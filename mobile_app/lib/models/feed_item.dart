enum ActivityCategory { travel, running, golf, gym }

class StatChip {
  final String icon;
  final String label;

  const StatChip({required this.icon, required this.label});
}

class CategoryMeta {
  final String label;
  final String emoji;
  final int color;
  final int bg;

  const CategoryMeta({
    required this.label,
    required this.emoji,
    required this.color,
    required this.bg,
  });
}
