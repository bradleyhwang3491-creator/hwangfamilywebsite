import 'feed_item.dart';

/// Unified shape the home feed renders — built from travel_records and
/// running_records rows (see providers/home_feed_provider.dart).
class FeedCardData {
  final String id;
  final ActivityCategory category;
  final String title;
  final String subtitle;
  final String? thumbnailUrl;
  final List<StatChip> stats;
  final String authorId;
  final DateTime sortDate;
  final String detailPath;

  const FeedCardData({
    required this.id,
    required this.category,
    required this.title,
    required this.subtitle,
    this.thumbnailUrl,
    required this.stats,
    required this.authorId,
    required this.sortDate,
    required this.detailPath,
  });
}
