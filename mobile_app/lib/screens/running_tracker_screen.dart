import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../config/theme.dart';
import '../models/running_record.dart';
import '../providers/running_records_provider.dart';
import '../providers/session_provider.dart';
import '../services/gps_track_service.dart';
import '../services/image_resize_service.dart';
import '../services/supabase_service.dart';

enum _Phase { setup, tracking, paused, review }

final _dateFmt = DateFormat('yyyy-MM-dd');
final _timerFmt = DateFormat('HH:mm:ss');

/// STEP1(일자/제목) → STEP2(실시간 GPS 트래킹 + 일시중단/종료 팝업) →
/// STEP3(경로 확인 + 거리/속도/최고심박수 저장) 전부를 한 화면에서 처리한다.
/// (스택을 나누면 GPS 스트림 생명주기 관리가 더 복잡해짐)
class RunningTrackerScreen extends ConsumerStatefulWidget {
  const RunningTrackerScreen({super.key});

  @override
  ConsumerState<RunningTrackerScreen> createState() => _RunningTrackerScreenState();
}

class _RunningTrackerScreenState extends ConsumerState<RunningTrackerScreen> {
  _Phase _phase = _Phase.setup;
  final _titleController = TextEditingController();
  DateTime _runDate = DateTime.now();

  DateTime? _startTime;
  DateTime? _endTime;

  final List<RoutePoint> _route = [];
  double _distanceMeters = 0;
  StreamSubscription<Position>? _positionSub;
  Timer? _ticker;
  Duration _elapsed = Duration.zero;
  String? _error;

  final _distanceController = TextEditingController();
  final _avgHrController = TextEditingController();
  final _maxHrController = TextEditingController();
  final _caloriesController = TextEditingController();
  Uint8List? _photoBytes;
  String? _photoFileName;
  bool _saving = false;

  @override
  void dispose() {
    _positionSub?.cancel();
    _ticker?.cancel();
    _titleController.dispose();
    _distanceController.dispose();
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
      _photoBytes = resized.bytes;
      _photoFileName = resized.fileName;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _runDate,
      firstDate: DateTime(_runDate.year - 5),
      lastDate: DateTime(_runDate.year + 1),
    );
    if (picked != null) setState(() => _runDate = picked);
  }

  Future<void> _handleStart() async {
    if (_titleController.text.trim().isEmpty) {
      setState(() => _error = '러닝 제목을 입력해주세요.');
      return;
    }
    bool granted;
    try {
      granted = await GpsTrackService.ensurePermission();
    } catch (_) {
      granted = false;
    }
    if (!granted) {
      setState(() => _error = '위치 권한이 필요해요. 설정에서 위치 권한을 허용해주세요.');
      return;
    }

    setState(() {
      _error = null;
      _startTime = DateTime.now();
      _phase = _Phase.tracking;
    });

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_phase == _Phase.tracking) setState(() => _elapsed += const Duration(seconds: 1));
    });

    _positionSub = GpsTrackService.positionStream().listen((position) {
      if (_phase != _Phase.tracking) return;
      final point = RoutePoint(lat: position.latitude, lng: position.longitude, timestamp: DateTime.now());
      setState(() {
        if (_route.isNotEmpty) {
          _distanceMeters += GpsTrackService.distanceBetween(
            _route.last.lat,
            _route.last.lng,
            point.lat,
            point.lng,
          );
        }
        _route.add(point);
      });
    }, onError: (_) {
      // GPS 신호 오류 등으로 스트림이 끊겨도 트래킹 자체는 계속 진행 (지금까지의 경로는 유지).
    });
  }

  void _togglePause() {
    if (_phase == _Phase.tracking) {
      setState(() => _phase = _Phase.paused);
    } else if (_phase == _Phase.paused) {
      setState(() {
        _phase = _Phase.tracking;
      });
    }
  }

  void _handleEnd() {
    _positionSub?.cancel();
    _ticker?.cancel();
    final end = DateTime.now();
    final distanceKm = _distanceMeters / 1000;

    _distanceController.text = distanceKm.toStringAsFixed(2);

    setState(() {
      _endTime = end;
      _phase = _Phase.review;
    });
  }

  Future<void> _handleSave() async {
    final user = ref.read(sessionProvider).valueOrNull;
    if (user == null || _startTime == null || _endTime == null) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final client = SupabaseService.client;
      final distanceMeters = (double.tryParse(_distanceController.text) ?? 0) * 1000;
      final durationSeconds = _elapsed.inSeconds;
      // 평균 속도는 거리/시간에서 다시 계산 — 거리 값을 수정해도 항상 일관되게 유지된다.
      final avgSpeedKmh =
          durationSeconds > 0 ? (distanceMeters / 1000) / (durationSeconds / 3600) : null;

      final inserted = await client
          .from('running_records')
          .insert({
            'user_id': user.id,
            'title': _titleController.text.trim(),
            'run_date': _dateFmt.format(_runDate),
            'start_time': _startTime!.toIso8601String(),
            'end_time': _endTime!.toIso8601String(),
            'duration_seconds': durationSeconds,
            'distance_meters': distanceMeters,
            'avg_speed_kmh': avgSpeedKmh,
            'avg_heart_rate': int.tryParse(_avgHrController.text),
            'max_heart_rate': int.tryParse(_maxHrController.text),
            'calories_burned': double.tryParse(_caloriesController.text),
            'route': _route.map((p) => p.toJson()).toList(),
          })
          .select()
          .single();

      final recordId = inserted['id'] as String;
      if (_photoBytes != null) {
        final ext = (_photoFileName ?? 'photo.jpg').split('.').last;
        final path = '$recordId/main-${DateTime.now().millisecondsSinceEpoch}.$ext';
        try {
          await client.storage.from('running-photos').uploadBinary(path, _photoBytes!);
          await client.from('running_records').update({'photo_path': path}).eq('id', recordId);
        } catch (_) {
          // 여행 기록과 동일하게, 사진 업로드 실패가 기록 저장 자체를 막지는 않는다.
        }
      }

      ref.invalidate(runningRecordsProvider(user.id));
      if (!mounted) return;
      context.pop();
    } catch (_) {
      setState(() {
        _saving = false;
        _error = '저장 중 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case _Phase.setup:
        return _buildSetup();
      case _Phase.tracking:
      case _Phase.paused:
        return _buildTracking();
      case _Phase.review:
        return _buildReview();
    }
  }

  Widget _buildSetup() {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.text900), onPressed: () => context.pop()),
        title: const Text('러닝 기록', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text900)),
        backgroundColor: AppColors.white,
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: AppColors.grayBorder)),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('러닝 일자', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text600)),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickDate,
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.grayBorder)),
                child: Text(_dateFmt.format(_runDate), style: const TextStyle(fontSize: 14, color: AppColors.text900)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('러닝 제목', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text600)),
            const SizedBox(height: 6),
            SizedBox(
              height: 48,
              child: TextField(
                controller: _titleController,
                decoration: const InputDecoration(hintText: '예: 한강 아침 러닝', contentPadding: EdgeInsets.symmetric(horizontal: 16)),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text900)),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _handleStart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('러닝 시작하기', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTracking() {
    final paused = _phase == _Phase.paused;
    final center = _route.isNotEmpty ? ll.LatLng(_route.last.lat, _route.last.lng) : const ll.LatLng(37.5665, 126.9780);

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(initialCenter: center, initialZoom: 16),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.hwangfamily.hwang_family_app',
              ),
              if (_route.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(points: _route.map((p) => ll.LatLng(p.lat, p.lng)).toList(), strokeWidth: 4, color: AppColors.primary600),
                  ],
                ),
              if (_route.isNotEmpty)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: center,
                      width: 16,
                      height: 16,
                      child: Container(decoration: BoxDecoration(color: AppColors.primary600, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2))),
                    ),
                  ],
                ),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(999), boxShadow: AppColors.shadowFloat),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_timerFmt.format(DateTime.utc(1970, 1, 1).add(_elapsed)), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.text900)),
                    const SizedBox(width: 12),
                    Text('${(_distanceMeters / 1000).toStringAsFixed(2)} km', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.text900)),
                  ],
                ),
              ),
            ),
          ),
          // 러닝 진행중 레이어드 팝업 — 뒤로가기/바깥 탭으로 안 닫힘
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppColors.shadowFloat),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(paused ? '일시중단됨' : '러닝 진행중', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text600)),
                    const SizedBox(height: 4),
                    Text(_timerFmt.format(DateTime.utc(1970, 1, 1).add(_elapsed)), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.text900)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _togglePause,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: AppColors.grayBorder),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(paused ? '재개' : '일시중단', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text900)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _handleEnd,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('종료', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReview() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('러닝 기록', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text900)),
        backgroundColor: AppColors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        shape: const Border(bottom: BorderSide(color: AppColors.grayBorder)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_route.isNotEmpty)
              Container(
                height: 220,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.grayBorder), boxShadow: AppColors.shadowCard),
                child: FlutterMap(
                  options: MapOptions(initialCenter: ll.LatLng(_route.first.lat, _route.first.lng), initialZoom: 15),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                      subdomains: const ['a', 'b', 'c', 'd'],
                      userAgentPackageName: 'com.hwangfamily.hwang_family_app',
                    ),
                    PolylineLayer(polylines: [Polyline(points: _route.map((p) => ll.LatLng(p.lat, p.lng)).toList(), strokeWidth: 4, color: AppColors.primary600)]),
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
            Text(_titleController.text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text900)),
            const SizedBox(height: 4),
            Text(_dateFmt.format(_runDate), style: const TextStyle(fontSize: 13, color: AppColors.text400)),
            const SizedBox(height: 20),
            // 러닝 시간과 평균 페이스는 트래킹 결과에서 계산되는 값이라 읽기 전용.
            Row(
              children: [
                Expanded(child: _ReadOnlyStat(label: '러닝 시간', value: RunningRecord.formatDuration(_elapsed.inSeconds))),
                const SizedBox(width: 8),
                Expanded(child: _ReadOnlyStat(label: '평균 페이스', value: _livePaceLabel())),
              ],
            ),
            const SizedBox(height: 16),
            _Field(
              label: '총 이동거리 (km)',
              child: _numInput(_distanceController, onChanged: (_) => setState(() {})),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _Field(label: '평균 심박수 (bpm)', child: _numInput(_avgHrController, hint: '선택'))),
                const SizedBox(width: 12),
                Expanded(child: _Field(label: '최고 심박수 (bpm)', child: _numInput(_maxHrController, hint: '선택'))),
              ],
            ),
            const SizedBox(height: 16),
            _Field(label: '총 칼로리 소모량 (kcal)', child: _numInput(_caloriesController, hint: '선택')),
            const SizedBox(height: 20),
            const Text('메인 사진', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text600)),
            const SizedBox(height: 6),
            _PhotoPicker(
              bytes: _photoBytes,
              onPick: _pickPhoto,
              onRemove: () => setState(() {
                _photoBytes = null;
                _photoFileName = null;
              }),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text900)),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(_saving ? '저장 중...' : '저장', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 사용자가 거리를 수정하면 페이스도 즉시 따라간다.
  String _livePaceLabel() {
    final km = double.tryParse(_distanceController.text) ?? 0;
    return RunningRecord.formatPace(km * 1000, _elapsed.inSeconds) ?? '-';
  }

  Widget _numInput(TextEditingController controller, {String? hint, ValueChanged<String>? onChanged}) {
    return SizedBox(
      height: 48,
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: onChanged,
        decoration: InputDecoration(hintText: hint, contentPadding: const EdgeInsets.symmetric(horizontal: 16)),
      ),
    );
  }
}

/// 계산으로 채워지는(수정 불가) 통계 한 칸.
class _ReadOnlyStat extends StatelessWidget {
  final String label;
  final String value;
  const _ReadOnlyStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text900)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.text400)),
        ],
      ),
    );
  }
}

/// 메인 사진 1장 선택/미리보기/삭제.
class _PhotoPicker extends StatelessWidget {
  final Uint8List? bytes;
  final VoidCallback onPick;
  final VoidCallback onRemove;
  const _PhotoPicker({required this.bytes, required this.onPick, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    if (bytes == null) {
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
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(bytes!, height: 180, width: double.infinity, fit: BoxFit.cover),
        ),
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
