import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../config/theme.dart';
import '../models/running_record.dart';
import '../providers/running_records_provider.dart';
import '../providers/session_provider.dart';
import '../services/image_resize_service.dart';
import '../services/supabase_service.dart';

final _dateFmt = DateFormat('yyyy-MM-dd');

/// 러닝 기록 상세. GPS 트래커(running_tracker_screen.dart)로 저장된
/// running_records를 id로 조회해서 보여준다. 수정/삭제는 작성자 본인만 가능.
class RunningRecordDetailScreen extends ConsumerStatefulWidget {
  final String recordId;
  const RunningRecordDetailScreen({super.key, required this.recordId});

  @override
  ConsumerState<RunningRecordDetailScreen> createState() => _RunningRecordDetailScreenState();
}

class _RunningRecordDetailScreenState extends ConsumerState<RunningRecordDetailScreen> {
  bool _loading = true;
  RunningRecord? _record;
  bool _editMode = false;
  bool _confirmingDelete = false;
  bool _saving = false;
  String? _error;

  final _titleController = TextEditingController();
  final _distanceController = TextEditingController();
  final _durationController = TextEditingController();
  final _paceController = TextEditingController();
  final _avgHrController = TextEditingController();
  final _maxHrController = TextEditingController();
  final _caloriesController = TextEditingController();

  /// 수정 모드에서 새로 고른 사진(저장 전까지 업로드하지 않음).
  Uint8List? _newPhotoBytes;
  String? _newPhotoFileName;
  bool _photoRemoved = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _distanceController.dispose();
    _durationController.dispose();
    _paceController.dispose();
    _avgHrController.dispose();
    _maxHrController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final resized = await ImageResizeService.resizeToLimit(bytes, file.name);
    if (!mounted) return;
    setState(() {
      _newPhotoBytes = resized.bytes;
      _newPhotoFileName = resized.fileName;
      _photoRemoved = false;
    });
  }

  Future<void> _load() async {
    final row = await SupabaseService.client
        .from('running_records')
        .select()
        .eq('id', widget.recordId)
        .maybeSingle();
    setState(() {
      _record = row == null ? null : RunningRecord.fromJson(row);
      _loading = false;
    });
  }

  void _enterEditMode(RunningRecord record) {
    _titleController.text = record.title;
    _distanceController.text = record.distanceKm.toStringAsFixed(2);
    _durationController.text = RunningRecord.formatDuration(record.durationSeconds);
    final pace = record.avgPaceSeconds ??
        RunningRecord.computePaceSeconds(record.distanceMeters, record.durationSeconds);
    _paceController.text = pace == null ? '' : RunningRecord.formatPaceInput(pace);
    _avgHrController.text = record.avgHeartRate?.toString() ?? '';
    _maxHrController.text = record.maxHeartRate?.toString() ?? '';
    _caloriesController.text = record.caloriesBurned?.toStringAsFixed(0) ?? '';
    setState(() {
      _error = null;
      _editMode = true;
      _newPhotoBytes = null;
      _newPhotoFileName = null;
      _photoRemoved = false;
    });
  }

  Future<void> _handleSave() async {
    final record = _record;
    if (record == null) return;
    if (_titleController.text.trim().isEmpty) {
      setState(() => _error = '제목을 입력해주세요.');
      return;
    }
    final durationSeconds = RunningRecord.parseDurationInput(_durationController.text);
    if (durationSeconds == null) {
      setState(() => _error = '러닝 시간을 MM:SS 형태로 입력해주세요.');
      return;
    }
    final paceSeconds = RunningRecord.parsePaceInput(_paceController.text);
    if (_paceController.text.trim().isNotEmpty && paceSeconds == null) {
      setState(() => _error = '평균 페이스를 분:초 형태로 입력해주세요.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final client = SupabaseService.client;
      final distanceMeters = (double.tryParse(_distanceController.text) ?? 0) * 1000;
      // 표시값은 페이스이므로 속도는 페이스에서 역산해 둘이 어긋나지 않게 한다.
      final avgSpeedKmh = paceSeconds != null && paceSeconds > 0 ? 3600 / paceSeconds : null;

      var photoPath = record.photoPath;
      if (_newPhotoBytes != null) {
        final ext = (_newPhotoFileName ?? 'photo.jpg').split('.').last;
        final path = '${record.id}/main-${DateTime.now().millisecondsSinceEpoch}.$ext';
        await client.storage.from('running-photos').uploadBinary(path, _newPhotoBytes!);
        if (record.photoPath != null) {
          try {
            await client.storage.from('running-photos').remove([record.photoPath!]);
          } catch (_) {
            // 예전 파일 정리 실패는 무시 — 새 사진은 이미 올라갔다.
          }
        }
        photoPath = path;
      } else if (_photoRemoved && record.photoPath != null) {
        try {
          await client.storage.from('running-photos').remove([record.photoPath!]);
        } catch (_) {
          // 위와 동일.
        }
        photoPath = null;
      }

      await client.from('running_records').update({
        'title': _titleController.text.trim(),
        'distance_meters': distanceMeters,
        'duration_seconds': durationSeconds,
        'avg_speed_kmh': avgSpeedKmh,
        'avg_pace_seconds': paceSeconds,
        'avg_heart_rate': int.tryParse(_avgHrController.text),
        'max_heart_rate': int.tryParse(_maxHrController.text),
        'calories_burned': double.tryParse(_caloriesController.text),
        'photo_path': photoPath,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', record.id);

      ref.invalidate(runningRecordsProvider(record.userId));
      setState(() {
        _saving = false;
        _editMode = false;
      });
      await _load();
    } catch (_) {
      setState(() {
        _saving = false;
        _error = '저장 중 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
      });
    }
  }

  Future<void> _handleDelete() async {
    final record = _record;
    if (record == null) return;
    setState(() => _saving = true);
    if (record.photoPath != null) {
      try {
        await SupabaseService.client.storage.from('running-photos').remove([record.photoPath!]);
      } catch (_) {
        // 스토리지 정리 실패가 기록 삭제를 막지는 않는다.
      }
    }
    await SupabaseService.client.from('running_records').delete().eq('id', record.id);
    ref.invalidate(runningRecordsProvider(record.userId));
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(sessionProvider).valueOrNull?.id;
    final isOwner = _record != null && currentUserId != null && currentUserId == _record!.userId;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.text900), onPressed: () => context.pop()),
        title: Text(_editMode ? '러닝 기록 수정' : '러닝 기록', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text900)),
        backgroundColor: AppColors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: const Border(bottom: BorderSide(color: AppColors.grayBorder)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _record == null
              ? const Center(child: Text('기록을 찾을 수 없습니다.', style: TextStyle(fontSize: 14, color: AppColors.text400)))
              : (_editMode ? _buildEditForm(_record!) : _buildContent(_record!, isOwner)),
    );
  }

  Widget _buildContent(RunningRecord record, bool isOwner) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (record.route.isNotEmpty)
            Container(
              height: 220,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.grayBorder), boxShadow: AppColors.shadowCard),
              child: FlutterMap(
                options: MapOptions(initialCenter: ll.LatLng(record.route.first.lat, record.route.first.lng), initialZoom: 15),
                children: [
                  TileLayer(
                    urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'com.hwangfamily.hwang_family_app',
                  ),
                  PolylineLayer(polylines: [Polyline(points: record.route.map((p) => ll.LatLng(p.lat, p.lng)).toList(), strokeWidth: 4, color: AppColors.primary600)]),
                ],
              ),
            )
          else
            Container(
              height: 120,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.gray100, borderRadius: BorderRadius.circular(16)),
              child: const Text('경로 데이터가 없어요', style: TextStyle(fontSize: 13, color: AppColors.text400)),
            ),
          const SizedBox(height: 20),
          Text(record.title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppColors.text900)),
          const SizedBox(height: 4),
          Text(_dateFmt.format(record.runDate), style: const TextStyle(fontSize: 13, color: AppColors.text400)),
          if (record.photoPath != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                SupabaseService.client.storage.from('running-photos').getPublicUrl(record.photoPath!),
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _StatCard(label: '총 이동거리', value: '${record.distanceKm.toStringAsFixed(2)} km')),
              const SizedBox(width: 8),
              Expanded(child: _StatCard(label: '평균 페이스', value: record.paceLabel != null ? '${record.paceLabel!} /km' : '-')),
              const SizedBox(width: 8),
              Expanded(child: _StatCard(label: '러닝 시간', value: record.durationLabel)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _StatCard(label: '평균 심박수', value: record.avgHeartRate != null ? '${record.avgHeartRate} bpm' : '-')),
              const SizedBox(width: 8),
              Expanded(child: _StatCard(label: '최고 심박수', value: record.maxHeartRate != null ? '${record.maxHeartRate} bpm' : '-')),
              const SizedBox(width: 8),
              Expanded(child: _StatCard(label: '칼로리', value: record.caloriesBurned != null ? '${record.caloriesBurned!.toStringAsFixed(0)} kcal' : '-')),
            ],
          ),
          if (isOwner) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _enterEditMode(record),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.grayBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('수정', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text900)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _confirmingDelete
                      ? Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _saving ? null : _handleDelete,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary600,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text(_saving ? '삭제 중...' : '정말 삭제', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => setState(() => _confirmingDelete = false),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  side: const BorderSide(color: AppColors.grayBorder),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('취소', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text600)),
                              ),
                            ),
                          ],
                        )
                      : OutlinedButton(
                          onPressed: () => setState(() => _confirmingDelete = true),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: AppColors.grayBorder),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('삭제', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text900)),
                        ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEditForm(RunningRecord record) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Field(label: '제목', child: _textInput(_titleController)),
          const SizedBox(height: 16),
          _Field(label: '총 이동거리 (km)', child: _textInput(_distanceController, keyboardType: TextInputType.number)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _Field(label: '러닝 시간 (MM:SS)', child: _textInput(_durationController))),
              const SizedBox(width: 12),
              Expanded(child: _Field(label: '평균 페이스 (분:초/km)', child: _textInput(_paceController))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _Field(label: '평균 심박수 (bpm)', child: _textInput(_avgHrController, keyboardType: TextInputType.number))),
              const SizedBox(width: 12),
              Expanded(child: _Field(label: '최고 심박수 (bpm)', child: _textInput(_maxHrController, keyboardType: TextInputType.number))),
            ],
          ),
          const SizedBox(height: 16),
          _Field(label: '총 칼로리 소모량 (kcal)', child: _textInput(_caloriesController, keyboardType: TextInputType.number)),
          const SizedBox(height: 20),
          const Text('메인 사진', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text600)),
          const SizedBox(height: 6),
          _EditablePhoto(
            newBytes: _newPhotoBytes,
            existingUrl: (!_photoRemoved && record.photoPath != null)
                ? SupabaseService.client.storage.from('running-photos').getPublicUrl(record.photoPath!)
                : null,
            onPick: _pickPhoto,
            onRemove: () => setState(() {
              _newPhotoBytes = null;
              _newPhotoFileName = null;
              _photoRemoved = true;
            }),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text900)),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _saving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(_saving ? '저장 중...' : '저장', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => setState(() => _editMode = false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.grayBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('취소', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.text600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _textInput(TextEditingController controller, {TextInputType? keyboardType}) {
    return SizedBox(
      height: 48,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 15, color: AppColors.text900),
        decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16)),
      ),
    );
  }
}

/// 수정 모드의 메인 사진 — 새로 고른 사진이 있으면 그걸, 없으면 기존 사진을 보여준다.
class _EditablePhoto extends StatelessWidget {
  final Uint8List? newBytes;
  final String? existingUrl;
  final VoidCallback onPick;
  final VoidCallback onRemove;
  const _EditablePhoto({
    required this.newBytes,
    required this.existingUrl,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final Widget? preview = newBytes != null
        ? Image.memory(newBytes!, height: 180, width: double.infinity, fit: BoxFit.cover)
        : existingUrl != null
            ? Image.network(existingUrl!, height: 180, width: double.infinity, fit: BoxFit.cover)
            : null;

    if (preview == null) {
      return InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 96,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.grayBorder),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_a_photo_outlined, size: 22, color: AppColors.text400),
              SizedBox(height: 6),
              Text('사진 추가', style: TextStyle(fontSize: 13, color: AppColors.text400)),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(12), child: preview),
        Positioned(
          top: 8,
          right: 8,
          child: Row(
            children: [
              _CircleAction(icon: Icons.edit, onTap: onPick),
              const SizedBox(width: 6),
              _CircleAction(icon: Icons.close, onTap: onRemove),
            ],
          ),
        ),
      ],
    );
  }
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), shape: BoxShape.circle),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final Widget child;
  const _Field({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text600)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.grayBorder)),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.text900)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.text400)),
        ],
      ),
    );
  }
}
