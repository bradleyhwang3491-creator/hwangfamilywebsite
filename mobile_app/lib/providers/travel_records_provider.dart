import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/travel_record.dart';
import '../services/supabase_service.dart';

class TravelData {
  final List<TravelRecord> records;
  final Map<String, String> thumbnails; // recordId -> first photo public URL

  TravelData({required this.records, required this.thumbnails});
}

/// Ported from TravelPage.tsx's two effects: travel_records list +
/// per-record first-photo thumbnail lookup.
final travelRecordsProvider = FutureProvider<TravelData>((ref) async {
  final client = SupabaseService.client;

  final recordRows = await client
      .from('travel_records')
      .select('id, user_id, title, region, address, country, lat, lng, is_domestic, start_date, end_date, content, created_at')
      .order('start_date', ascending: false);

  final records = (recordRows as List<dynamic>)
      .map((row) => TravelRecord.fromJson(row as Map<String, dynamic>))
      .toList();

  final photoRows = await client
      .from('travel_record_photos')
      .select('travel_record_id, storage_path, sort_order')
      .order('sort_order', ascending: true);

  final thumbnails = <String, String>{};
  for (final row in photoRows as List<dynamic>) {
    final recordId = row['travel_record_id'] as String;
    if (thumbnails.containsKey(recordId)) continue;
    final path = row['storage_path'] as String;
    thumbnails[recordId] = client.storage.from('travel-photos').getPublicUrl(path);
  }

  return TravelData(records: records, thumbnails: thumbnails);
});
