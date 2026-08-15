import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../config/theme.dart';
import '../providers/session_provider.dart';
import '../providers/travel_records_provider.dart';
import '../services/geocode_service.dart';
import '../services/image_resize_service.dart';
import '../services/supabase_service.dart';
import '../widgets/bottom_nav.dart';

const _maxPhotos = 10;
final _dateFmt = DateFormat('yyyy-MM-dd');

class _PhotoDraft {
  final Uint8List bytes;
  final String fileName;
  const _PhotoDraft({required this.bytes, required this.fileName});
}

/// Ported from src/pages/TravelRecordFormPage.tsx.
class TravelRecordFormScreen extends ConsumerStatefulWidget {
  const TravelRecordFormScreen({super.key});

  @override
  ConsumerState<TravelRecordFormScreen> createState() => _TravelRecordFormScreenState();
}

class _TravelRecordFormScreenState extends ConsumerState<TravelRecordFormScreen> {
  final _titleController = TextEditingController();
  final _regionController = TextEditingController();
  final _addressController = TextEditingController();
  final _contentController = TextEditingController();

  GeocodeResult? _geo;
  bool _geocoding = false;
  String? _geoError;
  DateTime? _startDate;
  DateTime? _endDate;
  final List<_PhotoDraft> _photos = [];
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _regionController.dispose();
    _addressController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  bool get _formValid =>
      _titleController.text.trim().isNotEmpty &&
      _regionController.text.trim().isNotEmpty &&
      _geo != null &&
      _startDate != null &&
      _endDate != null &&
      !_endDate!.isBefore(_startDate!) &&
      _contentController.text.trim().isNotEmpty;

  Future<void> _handleCheckAddress() async {
    if (_addressController.text.trim().isEmpty) return;
    setState(() {
      _geocoding = true;
      _geoError = null;
      _geo = null;
    });
    final result = await GeocodeService.geocodeAddress(_addressController.text.trim());
    setState(() {
      _geocoding = false;
      if (result == null) {
        _geoError = '주소를 찾지 못했습니다. 다르게 입력해보세요.';
      } else {
        _geo = result;
      }
    });
  }

  Future<void> _pickPhotos() async {
    final remaining = _maxPhotos - _photos.length;
    if (remaining <= 0) return;
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(limit: remaining);
    for (final file in files.take(remaining)) {
      final bytes = await file.readAsBytes();
      final resized = await ImageResizeService.resizeToLimit(bytes, file.name);
      if (!mounted) return;
      setState(() => _photos.add(_PhotoDraft(bytes: resized.bytes, fileName: resized.fileName)));
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = (isStart ? _startDate : _endDate) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 10),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formValid || _geo == null) return;

    final user = ref.read(sessionProvider).valueOrNull;
    if (user == null) {
      setState(() => _error = '로그인 정보가 없습니다. 다시 로그인해주세요.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final client = SupabaseService.client;
      final record = await client
          .from('travel_records')
          .insert({
            'user_id': user.id,
            'title': _titleController.text.trim(),
            'region': _regionController.text.trim(),
            'address': _addressController.text.trim(),
            'country': _geo!.country,
            'lat': _geo!.lat,
            'lng': _geo!.lng,
            'is_domestic': _geo!.isDomestic,
            'start_date': _dateFmt.format(_startDate!),
            'end_date': _dateFmt.format(_endDate!),
            'content': _contentController.text.trim(),
          })
          .select()
          .single();

      final recordId = record['id'] as String;
      for (var i = 0; i < _photos.length; i++) {
        final draft = _photos[i];
        final ext = draft.fileName.split('.').last;
        final path = '$recordId/$i-${DateTime.now().millisecondsSinceEpoch}.$ext';
        try {
          await client.storage.from('travel-photos').uploadBinary(path, draft.bytes);
          await client.from('travel_record_photos').insert({
            'travel_record_id': recordId,
            'storage_path': path,
            'sort_order': i,
          });
        } catch (_) {
          // Matches web behavior: a failed photo upload doesn't block the rest.
        }
      }

      ref.invalidate(travelRecordsProvider);
      if (!mounted) return;
      context.go('/travel');
    } catch (_) {
      setState(() {
        _submitting = false;
        _error = '저장 중 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('여행 기록 등록', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text900)),
        backgroundColor: AppColors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        automaticallyImplyLeading: false,
        shape: const Border(bottom: BorderSide(color: AppColors.grayBorder)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Field(
              label: '제목',
              child: _TextInput(controller: _titleController, hint: '예: 제주도 가족 여행', onChanged: (_) => setState(() {})),
            ),
            const SizedBox(height: 20),
            _Field(
              label: '지역',
              child: _TextInput(controller: _regionController, hint: '예: 제주 협재', onChanged: (_) => setState(() {})),
            ),
            const SizedBox(height: 20),
            _Field(
              label: '지역 주소',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _TextInput(
                          controller: _addressController,
                          hint: '예: 제주특별자치도 제주시 협재리',
                          onChanged: (_) => setState(() => _geo = null),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: (_addressController.text.trim().isEmpty || _geocoding) ? null : _handleCheckAddress,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary600,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: AppColors.primary600.withValues(alpha: 0.4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(_geocoding ? '확인 중' : '위치 확인', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                  if (_geoError != null) ...[
                    const SizedBox(height: 6),
                    Text(_geoError!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text900)),
                  ],
                  if (_geo != null) ...[
                    const SizedBox(height: 6),
                    Text('✓ 위치 확인됨 — ${_geo!.country ?? '알 수 없음'} (${_geo!.isDomestic ? '한국' : '해외'})', style: const TextStyle(fontSize: 12, color: AppColors.text600)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            _Field(
              label: '여행 일자',
              child: Row(
                children: [
                  Expanded(child: _DateInput(date: _startDate, onTap: () => _pickDate(isStart: true))),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('~', style: TextStyle(color: AppColors.text400))),
                  Expanded(child: _DateInput(date: _endDate, onTap: () => _pickDate(isStart: false))),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _Field(
              label: '여행 기록',
              child: TextField(
                controller: _contentController,
                maxLines: 6,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(hintText: '여행에서 있었던 일을 기록해보세요', contentPadding: EdgeInsets.all(16)),
              ),
            ),
            const SizedBox(height: 20),
            _Field(
              label: '사진 첨부 (${_photos.length}/$_maxPhotos)',
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 8, crossAxisSpacing: 8),
                itemCount: _photos.length + (_photos.length < _maxPhotos ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i == _photos.length) {
                    return InkWell(
                      onTap: _pickPhotos,
                      child: Container(
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.grayBorder)),
                        alignment: Alignment.center,
                        child: const Text('+', style: TextStyle(fontSize: 22, color: AppColors.text400)),
                      ),
                    );
                  }
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(_photos[i].bytes, width: double.infinity, height: double.infinity, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: InkWell(
                          onTap: () => setState(() => _photos.removeAt(i)),
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.75), shape: BoxShape.circle),
                            alignment: Alignment.center,
                            child: const Icon(Icons.close, size: 12, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text900)),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (_formValid && !_submitting) ? _handleSubmit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary600,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.primary600.withValues(alpha: 0.4),
                  disabledForegroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(_submitting ? '저장 중...' : '여행 기록 저장', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNav(currentPath: '/travel'),
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

class _TextInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  const _TextInput({required this.controller, required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 15, color: AppColors.text900),
        decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: AppColors.text400)),
      ),
    );
  }
}

class _DateInput extends StatelessWidget {
  final DateTime? date;
  final VoidCallback onTap;
  const _DateInput({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.grayBorder)),
        child: Text(
          date != null ? _dateFmt.format(date!) : '날짜 선택',
          style: TextStyle(fontSize: 14, color: date != null ? AppColors.text900 : AppColors.text400),
        ),
      ),
    );
  }
}
