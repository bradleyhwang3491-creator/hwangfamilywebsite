export type ActivityCategory = 'travel' | 'running' | 'golf' | 'gym';

export interface FamilyMember {
  id: string;
  name: string;
  avatarColor: string;
  initial: string;
}

export interface StatChip {
  icon: string;
  label: string;
}

export interface FeedItem {
  id: string;
  category: ActivityCategory;
  title: string;
  summary: string;
  thumbnail: string;
  createdAt: string;
  location?: string;
  stats: StatChip[];
  members: FamilyMember[];
  likeCount: number;
  imageCount?: number;
}

export interface CategoryMeta {
  label: string;
  emoji: string;
  color: string;
  bg: string;
}
