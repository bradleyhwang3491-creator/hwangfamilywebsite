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

export interface StatChip {
  icon: string;
  label: string;
}

export interface CategoryMeta {
  label: string;
  emoji: string;
  color: string;
  bg: string;
}

// Unified shape the home feed renders — built from travel_records and
// running_records rows (see lib/homeFeed.ts).
export interface FeedCardData {
  id: string;
  category: ActivityCategory;
  title: string;
  subtitle: string;
  thumbnailUrl?: string;
  stats: StatChip[];
  authorId: string;
  sortDate: string; // ISO date, for sorting only
  detailPath: string;
}

export interface RoutePoint {
  lat: number;
  lng: number;
  timestamp: string;
}

export interface RunningRecord {
  id: string;
  user_id: string;
  title: string;
  run_date: string;
  start_time: string;
  end_time: string;
  duration_seconds: number;
  distance_meters: number;
  avg_speed_kmh: number | null;
  max_heart_rate: number | null;
  route: RoutePoint[];
}
