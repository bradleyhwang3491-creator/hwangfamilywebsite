import { supabase } from './supabaseClient';
import type { FeedCardData } from '../types';

// 홈 피드 — travel_records + running_records(가족 전체, 유저 필터 없음)를
// 하나로 합쳐 최신순으로 정렬한다. golf/gym은 테이블이 없어 항상 빈 목록.
export async function loadHomeFeed(): Promise<FeedCardData[]> {
  const { data: travelRows } = await supabase
    .from('travel_records')
    .select('id, user_id, region, address, country, start_date, end_date, title')
    .order('start_date', { ascending: false });

  const { data: travelPhotoRows } = await supabase
    .from('travel_record_photos')
    .select('travel_record_id, storage_path, sort_order')
    .order('sort_order', { ascending: true });

  const thumbnails: Record<string, string> = {};
  for (const row of travelPhotoRows ?? []) {
    if (thumbnails[row.travel_record_id]) continue;
    thumbnails[row.travel_record_id] = supabase.storage.from('travel-photos').getPublicUrl(row.storage_path).data
      .publicUrl;
  }

  const travelCards: FeedCardData[] = (travelRows ?? []).map((row) => {
    const days =
      Math.round((new Date(row.end_date).getTime() - new Date(row.start_date).getTime()) / 86_400_000) + 1;
    return {
      id: row.id,
      category: 'travel',
      title: row.title,
      subtitle: `${row.start_date} ~ ${row.end_date}`,
      thumbnailUrl: thumbnails[row.id],
      stats: [
        { icon: '📍', label: row.region },
        { icon: '📅', label: `${days}일` },
      ],
      authorId: row.user_id,
      sortDate: row.start_date,
      detailPath: `/travel/record/${row.id}`,
    };
  });

  const { data: runningRows } = await supabase
    .from('running_records')
    .select('*')
    .order('start_time', { ascending: false });

  const runningCards: FeedCardData[] = (runningRows ?? []).map((row) => {
    const distanceKm = row.distance_meters / 1000;
    const stats = [{ icon: '🏃', label: `${distanceKm.toFixed(2)} km` }];
    if (row.avg_speed_kmh != null) stats.push({ icon: '⚡', label: `${row.avg_speed_kmh.toFixed(1)} km/h` });
    if (row.max_heart_rate != null) stats.push({ icon: '❤️', label: `최대 ${row.max_heart_rate} bpm` });

    return {
      id: row.id,
      category: 'running',
      title: row.title,
      subtitle: row.run_date,
      stats,
      authorId: row.user_id,
      sortDate: row.start_time,
      detailPath: `/running/record/${row.id}`,
    };
  });

  return [...travelCards, ...runningCards].sort(
    (a, b) => new Date(b.sortDate).getTime() - new Date(a.sortDate).getTime(),
  );
}
