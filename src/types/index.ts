export type ActivityCategory = 'travel' | 'running' | 'golf' | 'gym';

export interface AuthUser {
  id: string;
  username: string;
  name: string;
  phone_number: string | null;
  role: string;
  avatar_url: string | null;
}

export interface PublicUser {
  id: string;
  name: string;
  avatar_url: string | null;
}

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
