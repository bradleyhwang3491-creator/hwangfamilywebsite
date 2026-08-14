import { useState } from 'react';
import BottomNav from '../components/BottomNav';
import FeedCard from '../components/FeedCard';
import { CATEGORY_META, FAMILY, MOCK_FEED } from '../data/mockFeed';
import type { ActivityCategory } from '../types';

const FILTERS: { key: ActivityCategory | 'all'; label: string; emoji: string }[] = [
  { key: 'all', label: '전체', emoji: '✨' },
  { key: 'travel', label: '여행', emoji: '✈️' },
  { key: 'running', label: '러닝', emoji: '🏃' },
  { key: 'golf', label: '골프', emoji: '⛳' },
  { key: 'gym', label: '헬스', emoji: '💪' },
];

export default function HomePage() {
  const [filter, setFilter] = useState<ActivityCategory | 'all'>('all');

  const feed = filter === 'all' ? MOCK_FEED : MOCK_FEED.filter((f) => f.category === filter);

  return (
    <div className="app-frame">
      {/* Header */}
      <header className="safe-top px-5 pt-4 pb-3 bg-white sticky top-0 z-10 border-b border-gray-border">
        <div className="flex items-center justify-between mb-4">
          <div>
            <p className="text-[12px] text-text-400 mb-0.5">2026년 8월 14일 금요일</p>
            <h1 className="text-[20px] font-bold text-text-900">황이서네 라이프로그</h1>
          </div>
          <button
            aria-label="알림"
            className="relative w-10 h-10 rounded-full flex items-center justify-center bg-gray-100"
          >
            🔔
            <span
              className="absolute top-1.5 right-2 w-2 h-2 rounded-full"
              style={{ background: '#F97316' }}
            />
          </button>
        </div>

        {/* Family avatars row */}
        <div className="flex items-center gap-2 mb-4">
          {FAMILY.map((m) => (
            <div key={m.id} className="flex flex-col items-center gap-1">
              <span
                className="w-11 h-11 rounded-full flex items-center justify-center text-white text-[13px] font-bold border-2 border-white"
                style={{ background: m.avatarColor, boxShadow: 'var(--shadow-card)' }}
              >
                {m.initial}
              </span>
              <span className="text-[11px] text-text-600">{m.name}</span>
            </div>
          ))}
          <button
            className="w-11 h-11 rounded-full flex items-center justify-center text-text-400 text-[20px] border border-dashed"
            style={{ borderColor: '#E5E7EB' }}
            aria-label="가족 추가"
          >
            +
          </button>
        </div>

        {/* Category filter chips */}
        <div className="flex gap-2 overflow-x-auto no-scrollbar -mx-5 px-5">
          {FILTERS.map((f) => {
            const active = filter === f.key;
            const meta = f.key !== 'all' ? CATEGORY_META[f.key] : null;
            return (
              <button
                key={f.key}
                onClick={() => setFilter(f.key)}
                className="shrink-0 inline-flex items-center gap-1 text-[13px] font-semibold px-3.5 py-2 rounded-full border transition-colors"
                style={{
                  background: active ? (meta ? meta.bg : '#EFF6FF') : '#FFFFFF',
                  borderColor: active ? (meta ? meta.color : '#2563EB') : '#F1F3F5',
                  color: active ? (meta ? meta.color : '#2563EB') : '#4B5563',
                }}
              >
                <span>{f.emoji}</span>
                {f.label}
              </button>
            );
          })}
        </div>
      </header>

      {/* Stats summary strip */}
      <div className="px-5 py-4">
        <div
          className="rounded-2xl px-4 py-4 flex items-center justify-between text-white"
          style={{ background: 'linear-gradient(135deg, #2563EB 0%, #1E40AF 100%)' }}
        >
          <SummaryStat value="12" label="이번달 기록" />
          <div className="w-px h-8 bg-white/25" />
          <SummaryStat value="3" label="여행" />
          <div className="w-px h-8 bg-white/25" />
          <SummaryStat value="5" label="운동" />
          <div className="w-px h-8 bg-white/25" />
          <SummaryStat value="86" label="좋아요" />
        </div>
      </div>

      {/* Feed */}
      <main className="flex-1 px-5 pb-28 flex flex-col gap-3">
        {feed.length === 0 ? (
          <div className="flex flex-col items-center justify-center text-center py-20">
            <div className="text-4xl mb-3">🗂️</div>
            <h3 className="text-[16px] font-semibold text-text-900 mb-1">아직 기록이 없어요</h3>
            <p className="text-[13px] text-text-400 mb-5">가족과의 첫 기록을 남겨보세요</p>
            <button className="px-5 py-3 rounded-xl text-white text-[14px] font-medium" style={{ background: '#2563EB' }}>
              기록 추가하기
            </button>
          </div>
        ) : (
          feed.map((item) => <FeedCard key={item.id} item={item} />)
        )}
      </main>

      <BottomNav />
    </div>
  );
}

function SummaryStat({ value, label }: { value: string; label: string }) {
  return (
    <div className="flex-1 text-center">
      <p className="text-[18px] font-bold leading-tight">{value}</p>
      <p className="text-[11px] text-white/80 mt-0.5">{label}</p>
    </div>
  );
}
