import type { FeedItem } from '../types';
import { CATEGORY_META } from '../data/mockFeed';

export default function FeedCard({ item }: { item: FeedItem }) {
  const meta = CATEGORY_META[item.category];

  return (
    <article
      className="bg-white rounded-2xl border border-gray-border overflow-hidden"
      style={{ boxShadow: 'var(--shadow-card)' }}
    >
      <div className="relative">
        <img src={item.thumbnail} alt={item.title} className="w-full h-44 object-cover" loading="lazy" />
        {item.imageCount && item.imageCount > 1 && (
          <span className="absolute top-3 right-3 bg-black/55 text-white text-[11px] font-semibold px-2 py-1 rounded-full">
            +{item.imageCount}
          </span>
        )}
      </div>

      <div className="p-4">
        <div className="flex items-center justify-between mb-2">
          <span
            className="inline-flex items-center gap-1 text-[12px] font-semibold px-2.5 py-1 rounded-full"
            style={{ color: meta.color, background: meta.bg }}
          >
            <span>{meta.emoji}</span>
            {meta.label}
          </span>
          <span className="text-[12px] text-text-400">{item.createdAt}</span>
        </div>

        <h3 className="text-[16px] font-semibold text-text-900 leading-snug mb-1">{item.title}</h3>
        <p className="text-[14px] text-text-600 leading-relaxed line-clamp-2 mb-3">{item.summary}</p>

        <div className="flex flex-wrap gap-2 mb-3">
          {item.stats.map((s, i) => (
            <span
              key={i}
              className="inline-flex items-center gap-1 text-[12px] font-semibold text-text-900 bg-gray-100 rounded-lg px-2.5 py-1.5"
            >
              <span>{s.icon}</span>
              {s.label}
            </span>
          ))}
        </div>

        <div className="flex items-center justify-between pt-3 border-t border-gray-border">
          <div className="flex items-center -space-x-2">
            {item.members.map((m) => (
              <span
                key={m.id}
                className="w-6 h-6 rounded-full border-2 border-white flex items-center justify-center text-[10px] font-bold text-white"
                style={{ background: m.avatarColor }}
                title={m.name}
              >
                {m.initial}
              </span>
            ))}
          </div>
          <span className="flex items-center gap-1 text-[13px] text-text-600">
            <span>❤️</span>
            {item.likeCount}
          </span>
        </div>
      </div>
    </article>
  );
}
