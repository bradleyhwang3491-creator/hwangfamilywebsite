import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../config/theme.dart';
import '../models/running_record.dart';
import '../providers/running_records_provider.dart';
import '../providers/session_provider.dart';
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
  final _speedController = TextEditingController();
  final _maxHrController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _distanceController.dispose();
    _speedController.dispose();
    _maxHrController.dispose();
    super.dispose();
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
    _speedController.text = record.avgSpeedKmh?.toStringAsFixed(1) ?? '';
    _maxHrController.text = record.maxHeartRate?.toString() ?? '';
    setState(() {
      _error = null;
      _editMode = true;
    });
  }

  Future<void> _handleSave() async {
    final record = _record;
    if (record == null) return;
    if (_titleController.text.trim().isEmpty) {
      setState(() => _error = '제목을 입력해주세요.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await SupabaseService.client.from('running_records').update({
        'title': _titleController.text.trim(),
        'distance_meters': (double.tryParse(_distanceController.text) ?? 0) * 1000,
        'avg_speed_kmh': double.tryParse(_speedController.text),
        'max_heart_rate': int.tryParse(_maxHrController.text),
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
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _StatCard(label: '거리', value: '${record.distanceKm.toStringAsFixed(2)} km')),
              const SizedBox(width: 8),
              Expanded(child: _StatCard(label: '평균 속도', value: record.avgSpeedKmh != null ? '${record.avgSpeedKmh!.toStringAsFixed(1)} km/h' : '-')),
              const SizedBox(width: 8),
              Expanded(child: _StatCard(label: '최고 심박수', value: record.maxHeartRate != null ? '${record.maxHeartRate} bpm' : '-')),
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
          Row(
            children: [
              Expanded(child: _Field(label: '거리 (km)', child: _textInput(_distanceController, keyboardType: TextInputType.number))),
              const SizedBox(width: 12),
              Expanded(child: _Field(label: '평균 속도 (km/h)', child: _textInput(_speedController, keyboardType: TextInputType.number))),
            ],
          ),
          const SizedBox(height: 16),
          _Field(label: '최고 심박수 (bpm)', child: _textInput(_maxHrController, keyboardType: TextInputType.number)),
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
