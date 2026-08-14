import { useEffect, useState } from 'react';
import BottomNav from '../components/BottomNav';
import FeedCard from '../components/FeedCard';
import { supabase } from '../lib/supabaseClient';
import { CATEGORY_META, MOCK_FEED } from '../data/mockFeed';
import type { ActivityCategory, PublicUser } from '../types';

const AVATAR_COLORS = ['#111827', '#4B5563', '#6B7280', '#9CA3AF'];

const FILTERS: { key: ActivityCategory | 'all'; label: string; emoji: string }[] = [
  { key: 'all', label: '전체', emoji: '✨' },
  { key: 'travel', label: '여행', emoji: '✈️' },
  { key: 'running', label: '러닝', emoji: '🏃' },
  { key: 'golf', label: '골프', emoji: '⛳' },
  { key: 'gym', label: '헬스', emoji: '💪' },
];

const PAGE_SIZE = 10;

export default function HomePage() {
  const [filter, setFilter] = useState<ActivityCategory | 'all'>('all');
  const [page, setPage] = useState(1);
  const [familyMembers, setFamilyMembers] = useState<PublicUser[]>([]);

  useEffect(() => {
    supabase.rpc('list_family_members').then(({ data }) => {
      if (data) setFamilyMembers(data);
    });
  }, []);

  const filteredFeed = filter === 'all' ? MOCK_FEED : MOCK_FEED.filter((f) => f.category === filter);
  const totalPages = Math.max(1, Math.ceil(filteredFeed.length / PAGE_SIZE));
  const currentPage = Math.min(page, totalPages);
  const feed = filteredFeed.slice((currentPage - 1) * PAGE_SIZE, currentPage * PAGE_SIZE);

  function handleFilterChange(key: ActivityCategory | 'all') {
    setFilter(key);
    setPage(1);
  }

  return (
    <div className="app-frame">
      {/* Header */}
      <header className="safe-top px-5 pt-4 pb-3 bg-white sticky top-0 z-10 border-b border-gray-border">
        <div className="flex items-center justify-between mb-4">
          <h1 className="text-[20px] font-bold text-text-900">황이서네 라이프로그</h1>
        </div>

        {/* Family avatars row */}
        <div className="flex items-center gap-2 mb-4">
          {familyMembers.map((m, i) => (
            <div key={m.id} className="flex flex-col items-center gap-1">
              {m.avatar_url ? (
                <img
                  src={m.avatar_url}
                  alt={m.name}
                  className="w-11 h-11 rounded-full object-cover border-2 border-white"
                  style={{ boxShadow: 'var(--shadow-card)' }}
                />
              ) : (
                <span
                  className="w-11 h-11 rounded-full flex items-center justify-center text-white text-[13px] font-bold border-2 border-white"
                  style={{ background: AVATAR_COLORS[i % AVATAR_COLORS.length], boxShadow: 'var(--shadow-card)' }}
                >
                  {m.name.charAt(0)}
                </span>
              )}
              <span className="text-[11px] text-text-600">{m.name}</span>
            </div>
          ))}
        </div>

        {/* Category filter chips */}
        <div className="flex gap-2 overflow-x-auto no-scrollbar -mx-5 px-5">
          {FILTERS.map((f) => {
            const active = filter === f.key;
            const meta = f.key !== 'all' ? CATEGORY_META[f.key] : null;
            return (
              <button
                key={f.key}
                onClick={() => handleFilterChange(f.key)}
                className="shrink-0 inline-flex items-center gap-1 text-[13px] font-semibold px-3.5 py-2 rounded-full border transition-colors"
                style={{
                  background: active ? (meta ? meta.bg : '#F1F5F9') : '#FFFFFF',
                  borderColor: active ? '#111827' : '#E5E7EB',
                  color: active ? '#111827' : '#4B5563',
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
          style={{ background: 'linear-gradient(135deg, #1F2937 0%, #000000 100%)' }}
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
            <button className="px-5 py-3 rounded-xl text-white text-[14px] font-medium" style={{ background: '#111827' }}>
              기록 추가하기
            </button>
          </div>
        ) : (
          <>
            {feed.map((item) => (
              <FeedCard key={item.id} item={item} />
            ))}
            {totalPages > 1 && (
              <Pagination page={currentPage} totalPages={totalPages} onChange={setPage} />
            )}
          </>
        )}
      </main>

      <BottomNav />
    </div>
  );
}

function Pagination({
  page,
  totalPages,
  onChange,
}: {
  page: number;
  totalPages: number;
  onChange: (page: number) => void;
}) {
  return (
    <nav className="flex items-center justify-center gap-1.5 pt-3" aria-label="페이지 이동">
      <button
        type="button"
        onClick={() => onChange(Math.max(1, page - 1))}
        disabled={page === 1}
        aria-label="이전 페이지"
        className="w-8 h-8 rounded-lg flex items-center justify-center text-[13px] font-semibold border disabled:opacity-30"
        style={{ borderColor: '#E5E7EB', color: '#111827' }}
      >
        ‹
      </button>

      {Array.from({ length: totalPages }, (_, i) => i + 1).map((n) => {
        const active = n === page;
        return (
          <button
            key={n}
            type="button"
            onClick={() => onChange(n)}
            aria-current={active ? 'page' : undefined}
            className="w-8 h-8 rounded-lg text-[13px] font-semibold border"
            style={{
              background: active ? '#111827' : '#FFFFFF',
              borderColor: active ? '#111827' : '#E5E7EB',
              color: active ? '#FFFFFF' : '#4B5563',
            }}
          >
            {n}
          </button>
        );
      })}

      <button
        type="button"
        onClick={() => onChange(Math.min(totalPages, page + 1))}
        disabled={page === totalPages}
        aria-label="다음 페이지"
        className="w-8 h-8 rounded-lg flex items-center justify-center text-[13px] font-semibold border disabled:opacity-30"
        style={{ borderColor: '#E5E7EB', color: '#111827' }}
      >
        ›
      </button>
    </nav>
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
