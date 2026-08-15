import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/running_record.dart';
import '../services/supabase_service.dart';

/// Currently selected year/month on RunningScreen (day/time components ignored).
final selectedRunningMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

/// All running_records for a given user (RunningScreen filters by month
/// client-side, same approach as travel_records_provider.dart).
final runningRecordsProvider = FutureProvider.family<List<RunningRecord>, String>((ref, userId) async {
  final rows = await SupabaseService.client
      .from('running_records')
      .select()
      .eq('user_id', userId)
      .order('start_time', ascending: false);

  return (rows as List<dynamic>)
      .map((row) => RunningRecord.fromJson(row as Map<String, dynamic>))
      .toList();
});
