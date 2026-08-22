import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../config/theme.dart';
import '../models/travel_record.dart';
import '../models/travel_record_photo.dart';
import '../providers/session_provider.dart';
import '../providers/travel_records_provider.dart';
import '../services/geocode_service.dart';
import '../services/image_resize_service.dart';
import '../services/supabase_service.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/photo_lightbox.dart';

const _maxPhotos = 20;
final _dateFmt = DateFormat('yyyy-MM-dd');

class _NewPhotoDraft {
  final Uint8List bytes;
  final String fileName;
  const _NewPhotoDraft({required this.bytes, required this.fileName});
}

/// Ported from src/pages/TravelRecordDetailPage.tsx.
class TravelRecordDetailScreen extends ConsumerStatefulWidget {
  final String recordId;
  const TravelRecordDetailScreen({super.key, required this.recordId});

  @override
  ConsumerState<TravelRecordDetailScreen> createState() => _TravelRecordDetailScreenState();
}

class _TravelRecordDetailScreenState extends ConsumerState<TravelRecordDetailScreen> {
  TravelRecord? _record;
  List<TravelRecordPhoto> _photos = [];
  bool _loading = true;
  bool _notFound = false;
  bool _editMode = false;
  bool _confirmingDelete = false;
  int? _lightboxIndex;
  String? _error;
  bool _saving = false;

  final _titleController = TextEditingController();
  final _regionController = TextEditingController();
  final _addressController = TextEditingController();
  final _contentController = TextEditingController();
  GeocodeResult? _geo;
  bool _geocoding = false;
  String? _geoError;
  DateTime? _startDate;
  DateTime? _endDate;
  final List<String> _removedPhotoIds = [];
  final List<_NewPhotoDraft> _newPhotos = [];

  @override
  void initState() {
    super.initState();
    _loadRecord();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _regionController.dispose();
    _addressController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadRecord() async {
    setState(() => _loading = true);
    final client = SupabaseService.client;
    final row = await client
        .from('travel_records')
        .select('id, user_id, title, region, address, country, lat, lng, is_domestic, start_date, end_date, content, created_at')
        .eq('id', widget.recordId)
        .maybeSingle();

    if (row == null) {
      setState(() {
        _notFound = true;
        _loading = false;
      });
      return;
    }

    final photoRows = await client
        .from('travel_record_photos')
        .select('id, storage_path, sort_order')
        .eq('travel_record_id', widget.recordId)
        .order('sort_order');

    final photos = (photoRows as List<dynamic>)
        .map((p) => TravelRecordPhoto(
              id: p['id'] as String,
              travelRecordId: widget.recordId,
              storagePath: p['storage_path'] as String,
              sortOrder: p['sort_order'] as int,
              url: client.storage.from('travel-photos').getPublicUrl(p['storage_path'] as String),
            ))
        .toList();

    setState(() {
      _record = TravelRecord.fromJson(row);
      _photos = photos;
      _loading = false;
    });
  }

  void _enterEditMode() {
    final record = _record;
    if (record == null) return;
    _titleController.text = record.title;
    _regionController.text = record.region;
    _addressController.text = record.address;
    _geo = (record.lat != null && record.lng != null)
        ? GeocodeResult(lat: record.lat!, lng: record.lng!, country: record.country, isDomestic: record.isDomestic ?? false)
        : null;
    _startDate = DateTime.parse(record.startDate);
    _endDate = DateTime.parse(record.endDate);
    _contentController.text = record.content;
    _removedPhotoIds.clear();
    _newPhotos.clear();
    setState(() {
      _error = null;
      _editMode = true;
    });
  }

  void _cancelEdit() {
    setState(() {
      _newPhotos.clear();
      _removedPhotoIds.clear();
      _editMode = false;
    });
  }

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

  int get _remainingExistingCount => _photos.where((p) => !_removedPhotoIds.contains(p.id)).length;

  Future<void> _pickPhotos() async {
    final remaining = _maxPhotos - _remainingExistingCount - _newPhotos.length;
    if (remaining <= 0) return;
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(limit: remaining);
    for (final file in files.take(remaining)) {
      final bytes = await file.readAsBytes();
      final resized = await ImageResizeService.resizeToLimit(bytes, file.name);
      if (!mounted) return;
      setState(() => _newPhotos.add(_NewPhotoDraft(bytes: resized.bytes, fileName: resized.fileName)));
    }
  }

  bool get _formValid =>
      _titleController.text.trim().isNotEmpty &&
      _regionController.text.trim().isNotEmpty &&
      _geo != null &&
      _startDate != null &&
      _endDate != null &&
      !_endDate!.isBefore(_startDate!) &&
      _contentController.text.trim().isNotEmpty;

  Future<void> _handleSave() async {
    final record = _record;
    if (record == null || !_formValid || _geo == null) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final client = SupabaseService.client;
    try {
      await client.from('travel_records').update({
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
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', record.id);

      if (_removedPhotoIds.isNotEmpty) {
        final removed = _photos.where((p) => _removedPhotoIds.contains(p.id)).toList();
        await client.storage.from('travel-photos').remove(removed.map((p) => p.storagePath).toList());
        await client.from('travel_record_photos').delete().inFilter('id', _removedPhotoIds);
      }

      var sortOrder = _remainingExistingCount;
      for (final draft in _newPhotos) {
        final ext = draft.fileName.split('.').last;
        final path = '${record.id}/$sortOrder-${DateTime.now().millisecondsSinceEpoch}.$ext';
        try {
          await client.storage.from('travel-photos').uploadBinary(path, draft.bytes);
          await client.from('travel_record_photos').insert({
            'travel_record_id': record.id,
            'storage_path': path,
            'sort_order': sortOrder,
          });
        } catch (_) {
          // Matches web behavior: a failed photo upload doesn't block the rest.
        }
        sortOrder++;
      }

      ref.invalidate(travelRecordsProvider);
      _newPhotos.clear();
      setState(() {
        _editMode = false;
        _saving = false;
      });
      await _loadRecord();
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
    final client = SupabaseService.client;
    if (_photos.isNotEmpty) {
      await client.storage.from('travel-photos').remove(_photos.map((p) => p.storagePath).toList());
    }
    await client.from('travel_records').delete().eq('id', record.id);
    ref.invalidate(travelRecordsProvider);
    if (!mounted) return;
    context.go('/travel');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: _detailAppBar(() => context.go('/travel'), '기록 상세'),
        bottomNavigationBar: const BottomNav(currentPath: '/travel'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_notFound || _record == null) {
      return Scaffold(
        appBar: _detailAppBar(() => context.go('/travel'), '기록 상세'),
        bottomNavigationBar: const BottomNav(currentPath: '/travel'),
        body: const Center(child: Text('기록을 찾을 수 없습니다.', style: TextStyle(fontSize: 14, color: AppColors.text400))),
      );
    }

    final record = _record!;
    final currentUserId = ref.watch(sessionProvider).valueOrNull?.id;
    final isOwner = currentUserId != null && currentUserId == record.userId;

    return Scaffold(
      appBar: _detailAppBar(() => context.go('/travel'), _editMode ? '기록 수정' : '기록 상세'),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: _editMode ? _buildEditForm() : _buildView(record, isOwner),
          ),
          if (_lightboxIndex != null && _lightboxIndex! < _photos.length)
            PhotoLightbox(
              photos: _photos,
              index: _lightboxIndex!,
              onClose: () => setState(() => _lightboxIndex = null),
              onChangeIndex: (i) => setState(() => _lightboxIndex = i),
            ),
        ],
      ),
      bottomNavigationBar: const BottomNav(currentPath: '/travel'),
    );
  }

  Widget _buildView(TravelRecord record, bool isOwner) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(record.title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppColors.text900)),
        const SizedBox(height: 4),
        Text('${record.country ?? ''} ${record.country != null ? '·' : ''} ${record.region}', style: const TextStyle(fontSize: 13, color: AppColors.text600)),
        const SizedBox(height: 2),
        Text('${record.startDate} ~ ${record.endDate} · ${record.days}일', style: const TextStyle(fontSize: 12, color: AppColors.text400)),
        if (_photos.isNotEmpty) ...[
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8),
            itemCount: _photos.length,
            itemBuilder: (context, i) => InkWell(
              onTap: () => setState(() => _lightboxIndex = i),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(_photos[i].url, fit: BoxFit.cover),
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text(record.content, style: const TextStyle(fontSize: 14, color: AppColors.text900, height: 1.5)),
        if (isOwner) ...[
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _enterEditMode,
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
    );
  }

  Widget _buildEditForm() {
    final remainingPhotos = _photos.where((p) => !_removedPhotoIds.contains(p.id)).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Field(label: '제목', child: _textInput(_titleController)),
        const SizedBox(height: 20),
        _Field(label: '지역', child: _textInput(_regionController)),
        const SizedBox(height: 20),
        _Field(
          label: '지역 주소',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _textInput(_addressController, onChanged: (_) => setState(() => _geo = null)),
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
              Expanded(child: _dateInput(_startDate, () => _pickDate(isStart: true))),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('~', style: TextStyle(color: AppColors.text400))),
              Expanded(child: _dateInput(_endDate, () => _pickDate(isStart: false))),
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
            decoration: const InputDecoration(contentPadding: EdgeInsets.all(16)),
          ),
        ),
        const SizedBox(height: 20),
        _Field(
          label: '사진 첨부 (${remainingPhotos.length + _newPhotos.length}/$_maxPhotos)',
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 8, crossAxisSpacing: 8),
            itemCount: remainingPhotos.length + _newPhotos.length + ((remainingPhotos.length + _newPhotos.length) < _maxPhotos ? 1 : 0),
            itemBuilder: (context, i) {
              if (i < remainingPhotos.length) {
                final p = remainingPhotos[i];
                return _photoTile(
                  image: Image.network(p.url, fit: BoxFit.cover),
                  onRemove: () => setState(() => _removedPhotoIds.add(p.id)),
                );
              }
              final newIndex = i - remainingPhotos.length;
              if (newIndex < _newPhotos.length) {
                final draft = _newPhotos[newIndex];
                return _photoTile(
                  image: Image.memory(draft.bytes, fit: BoxFit.cover),
                  onRemove: () => setState(() => _newPhotos.removeAt(newIndex)),
                );
              }
              return InkWell(
                onTap: _pickPhotos,
                child: Container(
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.grayBorder)),
                  alignment: Alignment.center,
                  child: const Text('+', style: TextStyle(fontSize: 22, color: AppColors.text400)),
                ),
              );
            },
          ),
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
                onPressed: (_formValid && !_saving) ? _handleSave : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary600,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.primary600.withValues(alpha: 0.4),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(_saving ? '저장 중...' : '저장', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: _saving ? null : _cancelEdit,
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
    );
  }

  Widget _photoTile({required Widget image, required VoidCallback onRemove}) {
    return Stack(
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(8), child: SizedBox.expand(child: image)),
        Positioned(
          top: 4,
          right: 4,
          child: InkWell(
            onTap: onRemove,
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
  }

  Widget _textInput(TextEditingController controller, {ValueChanged<String>? onChanged}) {
    return SizedBox(
      height: 48,
      child: TextField(
        controller: controller,
        onChanged: (v) {
          onChanged?.call(v);
          setState(() {});
        },
        style: const TextStyle(fontSize: 15, color: AppColors.text900),
        decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16)),
      ),
    );
  }

  Widget _dateInput(DateTime? date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.grayBorder)),
        child: Text(
          date != null ? _dateFmt.format(date) : '날짜 선택',
          style: TextStyle(fontSize: 14, color: date != null ? AppColors.text900 : AppColors.text400),
        ),
      ),
    );
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
}

AppBar _detailAppBar(VoidCallback onBack, String title) {
  return AppBar(
    leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.text900), onPressed: onBack),
    title: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text900)),
    backgroundColor: AppColors.white,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    centerTitle: false,
    shape: const Border(bottom: BorderSide(color: AppColors.grayBorder)),
  );
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
