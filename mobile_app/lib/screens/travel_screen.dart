import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../config/theme.dart';
import '../models/travel_record.dart';
import '../providers/travel_records_provider.dart';
import '../widgets/bottom_nav.dart';

class _PinRecord {
  final String id;
  final String title;
  final String startDate;
  final String endDate;
  final String region;
  final String address;
  final String? thumbnailUrl;

  _PinRecord({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.region,
    required this.address,
    required this.thumbnailUrl,
  });
}

class _MapPin {
  final String key;
  final double lat;
  final double lng;
  final String region;
  final String? country;
  final List<_PinRecord> records;

  _MapPin({
    required this.key,
    required this.lat,
    required this.lng,
    required this.region,
    required this.country,
    required this.records,
  });
}

/// Ported from src/pages/TravelPage.tsx — flutter_map replaces react-leaflet,
/// same CARTO light tile basemap.
class TravelScreen extends ConsumerStatefulWidget {
  const TravelScreen({super.key});

  @override
  ConsumerState<TravelScreen> createState() => _TravelScreenState();
}

class _TravelScreenState extends ConsumerState<TravelScreen> {
  String? _selectedKey;

  List<_MapPin> _buildPins(List<TravelRecord> records, Map<String, String> thumbnails) {
    final groups = <String, _MapPin>{};
    for (final r in records) {
      if (r.lat == null || r.lng == null) continue;
      final key = '${r.country ?? ''}__${r.region.trim().toLowerCase()}';
      final rec = _PinRecord(
        id: r.id,
        title: r.title,
        startDate: r.startDate,
        endDate: r.endDate,
        region: r.region,
        address: r.address,
        thumbnailUrl: thumbnails[r.id],
      );
      final existing = groups[key];
      if (existing != null) {
        existing.records.add(rec);
      } else {
        groups[key] = _MapPin(key: key, lat: r.lat!, lng: r.lng!, region: r.region, country: r.country, records: [rec]);
      }
    }
    return groups.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    final travelAsync = ref.watch(travelRecordsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.text900), onPressed: () => context.go('/home')),
        title: const Text('여행 기록하기', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text900)),
        backgroundColor: AppColors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        shape: const Border(bottom: BorderSide(color: AppColors.grayBorder)),
      ),
      body: travelAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('불러오지 못했습니다: $e')),
        data: (data) {
          final records = data.records;
          final pins = _buildPins(records, data.thumbnails);
          final selectedPin = pins.where((p) => p.key == _selectedKey).firstOrNull;

          final countries = records.map((r) => r.country).whereType<String>().toSet();
          final regions = records.map((r) => r.region).toSet();
          final domesticDays = records.where((r) => r.isDomestic == true).fold<int>(0, (sum, r) => sum + r.days);
          final overseasDays = records.where((r) => r.isDomestic == false).fold<int>(0, (sum, r) => sum + r.days);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: [
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/travel/new'),
                  icon: const Text('+', style: TextStyle(fontSize: 17, color: Colors.white)),
                  label: const Text('여행기록하기', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary600,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('여행 종합 리뷰', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text900)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _StatCard(label: '방문 국가', value: '${countries.length}개국')),
                  const SizedBox(width: 8),
                  Expanded(child: _StatCard(label: '방문 지역', value: '${regions.length}곳')),
                  const SizedBox(width: 8),
                  Expanded(child: _StatCard(label: '총 여행일', value: '${domesticDays + overseasDays}일')),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _SubStat(label: '한국', value: '$domesticDays일')),
                  const SizedBox(width: 8),
                  Expanded(child: _SubStat(label: '해외', value: '$overseasDays일')),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 320,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.grayBorder),
                  boxShadow: AppColors.shadowCard,
                ),
                child: FlutterMap(
                  options: const MapOptions(initialCenter: LatLng(30, 128), initialZoom: 3),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                      subdomains: const ['a', 'b', 'c', 'd'],
                      userAgentPackageName: 'com.hwangfamily.hwang_family_app',
                    ),
                    MarkerLayer(
                      markers: [
                        for (final pin in pins)
                          Marker(
                            point: LatLng(pin.lat, pin.lng),
                            width: 16,
                            height: 16,
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedKey = pin.key),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.primary600,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.white, width: 2),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (records.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text(
                    '아직 등록된 여행 기록이 없어요. 첫 기록을 남겨보세요!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppColors.text400),
                  ),
                ),
              if (selectedPin != null) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${selectedPin.country ?? ''} ${selectedPin.country != null ? '·' : ''} ${selectedPin.region} · 기록 ${selectedPin.records.length}건',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text600),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _selectedKey = null),
                      child: const Text('닫기', style: TextStyle(fontSize: 12, color: AppColors.text400)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                for (final r in selectedPin.records) ...[
                  _RecordRow(record: r, onTap: () => context.push('/travel/record/${r.id}')),
                  const SizedBox(height: 12),
                ],
              ],
            ],
          );
        },
      ),
      bottomNavigationBar: const BottomNav(currentPath: '/travel'),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
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
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text900)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.text400)),
        ],
      ),
    );
  }
}

class _SubStat extends StatelessWidget {
  final String label;
  final String value;
  const _SubStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: AppColors.gray100, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.text600)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.text900)),
        ],
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  final _PinRecord record;
  final VoidCallback onTap;
  const _RecordRow({required this.record, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.grayBorder),
          boxShadow: AppColors.shadowCard,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 80,
              height: 80,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: AppColors.gray100),
              child: record.thumbnailUrl != null
                  ? Image.network(record.thumbnailUrl!, fit: BoxFit.cover)
                  : const Center(child: Text('🖼️', style: TextStyle(fontSize: 22, color: AppColors.text400))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(record.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text900)),
                  const SizedBox(height: 2),
                  Text('${record.startDate} ~ ${record.endDate}', style: const TextStyle(fontSize: 12, color: AppColors.text400)),
                  const SizedBox(height: 2),
                  Text('${record.region} · ${record.address}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.text600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
