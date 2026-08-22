import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/feed_card_data.dart';
import '../models/feed_item.dart';
import '../models/running_record.dart';
import '../services/supabase_service.dart';

final _dateFmt = DateFormat('yyyy-MM-dd');

/// 홈 피드 — travel_records + running_records(가족 전체, 유저 필터 없음)를
/// 하나로 합쳐 최신순으로 정렬한다. golf/gym은 테이블이 없어 항상 빈 목록.
final homeFeedProvider = FutureProvider<List<FeedCardData>>((ref) async {
  final client = SupabaseService.client;

  final travelRows = await client
      .from('travel_records')
      .select('id, user_id, region, address, country, start_date, end_date, title')
      .order('start_date', ascending: false);

  final travelPhotoRows = await client
      .from('travel_record_photos')
      .select('travel_record_id, storage_path, sort_order')
      .order('sort_order', ascending: true);

  final thumbnails = <String, String>{};
  for (final row in travelPhotoRows as List<dynamic>) {
    final recordId = row['travel_record_id'] as String;
    if (thumbnails.containsKey(recordId)) continue;
    thumbnails[recordId] = client.storage.from('travel-photos').getPublicUrl(row['storage_path'] as String);
  }

  final travelCards = (travelRows as List<dynamic>).map((row) {
    final id = row['id'] as String;
    final startDate = row['start_date'] as String;
    final endDate = row['end_date'] as String;
    final days = DateTime.parse(endDate).difference(DateTime.parse(startDate)).inDays + 1;
    return FeedCardData(
      id: id,
      category: ActivityCategory.travel,
      title: row['title'] as String,
      subtitle: '$startDate ~ $endDate',
      thumbnailUrl: thumbnails[id],
      stats: [
        StatChip(icon: '📍', label: row['region'] as String),
        StatChip(icon: '📅', label: '$days일'),
      ],
      authorId: row['user_id'] as String,
      sortDate: DateTime.parse(startDate),
      detailPath: '/travel/record/$id',
    );
  }).toList();

  final runningRows = await client.from('running_records').select().order('start_time', ascending: false);

  final runningCards = (runningRows as List<dynamic>).map((row) {
    final id = row['id'] as String;
    final distanceMeters = (row['distance_meters'] as num).toDouble();
    final durationSeconds = row['duration_seconds'] as int;
    final maxHr = row['max_heart_rate'] as int?;
    final calories = (row['calories_burned'] as num?)?.toDouble();
    final photoPath = row['photo_path'] as String?;
    final pace = RunningRecord.formatPace(distanceMeters, durationSeconds);
    final startTime = DateTime.parse(row['start_time'] as String);
    return FeedCardData(
      id: id,
      category: ActivityCategory.running,
      title: row['title'] as String,
      subtitle: _dateFmt.format(DateTime.parse(row['run_date'] as String)),
      thumbnailUrl:
          photoPath == null ? null : client.storage.from('running-photos').getPublicUrl(photoPath),
      stats: [
        StatChip(icon: '🏃', label: '${(distanceMeters / 1000).toStringAsFixed(2)} km'),
        if (pace != null) StatChip(icon: '⚡', label: '$pace /km'),
        StatChip(icon: '⏱️', label: RunningRecord.formatDuration(durationSeconds)),
        if (maxHr != null) StatChip(icon: '❤️', label: '최대 $maxHr bpm'),
        if (calories != null) StatChip(icon: '🔥', label: '${calories.toStringAsFixed(0)} kcal'),
      ],
      authorId: row['user_id'] as String,
      sortDate: startTime,
      detailPath: '/running/record/$id',
    );
  }).toList();

  final all = [...travelCards, ...runningCards];
  all.sort((a, b) => b.sortDate.compareTo(a.sortDate));
  return all;
});
