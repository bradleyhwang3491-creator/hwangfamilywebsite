import '../models/feed_item.dart';

/// Category badge colors (unchanged grayscale design) + a separate
/// per-category accent used only for the feed card's outer border.
const categoryMeta = <ActivityCategory, CategoryMeta>{
  ActivityCategory.travel: CategoryMeta(label: '여행', emoji: '✈️', color: 0xFF111827, bg: 0xFFF1F5F9),
  ActivityCategory.running: CategoryMeta(label: '러닝', emoji: '🏃', color: 0xFF111827, bg: 0xFFF1F5F9),
  ActivityCategory.golf: CategoryMeta(label: '골프', emoji: '⛳', color: 0xFF111827, bg: 0xFFF1F5F9),
  ActivityCategory.gym: CategoryMeta(label: '헬스', emoji: '💪', color: 0xFF111827, bg: 0xFFF1F5F9),
};

const categoryBorderColor = <ActivityCategory, int>{
  ActivityCategory.travel: 0xFF3B82F6, // blue
  ActivityCategory.running: 0xFFF97316, // orange
  ActivityCategory.golf: 0xFF22C55E, // green
  ActivityCategory.gym: 0xFFEF4444, // red
};
