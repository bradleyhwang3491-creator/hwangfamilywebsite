import type { ActivityCategory, CategoryMeta } from '../types';

// Category badge colors (unchanged grayscale design) + a separate
// per-category accent used only for the feed card's outer border.
export const CATEGORY_META: Record<ActivityCategory, CategoryMeta> = {
  travel: { label: '여행', emoji: '✈️', color: '#111827', bg: '#F1F5F9' },
  running: { label: '러닝', emoji: '🏃', color: '#111827', bg: '#F1F5F9' },
  golf: { label: '골프', emoji: '⛳', color: '#111827', bg: '#F1F5F9' },
  gym: { label: '헬스', emoji: '💪', color: '#111827', bg: '#F1F5F9' },
};

export const CATEGORY_BORDER_COLOR: Record<ActivityCategory, string> = {
  travel: '#3B82F6', // blue
  running: '#F97316', // orange
  golf: '#22C55E', // green
  gym: '#EF4444', // red
};
