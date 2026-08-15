import { useNavigate } from 'react-router-dom';
import type { FeedCardData } from '../types';
import { CATEGORY_META, CATEGORY_BORDER_COLOR } from '../data/categoryMeta';

// Real DB-backed data (travel_records/running_records) instead of mock feed
// items. No more like button; shows the author instead, and the outer
// border is colored per category.
export default function FeedCard({
  item,
  authorName,
  authorAvatarColor,
}: {
  item: FeedCardData;
  authorName: string;
  authorAvatarColor: string;
}) {
  const navigate = useNavigate();
  const meta = CATEGORY_META[item.category];
  const borderColor = CATEGORY_BORDER_COLOR[item.category];

  return (
    <article
      onClick={() => navigate(item.detailPath)}
      className="bg-white rounded-2xl overflow-hidden cursor-pointer"
      style={{ boxShadow: 'var(--shadow-card)', border: `1.5px solid ${borderColor}` }}
    >
      {item.thumbnailUrl && (
        <img src={item.thumbnailUrl} alt={item.title} className="w-full h-44 object-cover" loading="lazy" />
      )}

      <div className="p-3">
        <div className="flex items-center justify-between mb-1.5">
          <span
            className="inline-flex items-center gap-1 text-[11px] font-semibold px-2 py-0.5 rounded-full"
            style={{ color: meta.color, background: meta.bg }}
          >
            <span>{meta.emoji}</span>
            {meta.label}
          </span>
          <span className="text-[11px] text-text-400">{item.subtitle}</span>
        </div>

        <h3 className="text-[14px] font-semibold text-text-900 leading-snug mb-1.5 truncate">{item.title}</h3>

        <div className="flex flex-wrap gap-1.5 mb-2">
          {item.stats.map((s, i) => (
            <span
              key={i}
              className="inline-flex items-center gap-1 text-[11px] font-semibold text-text-900 bg-gray-100 rounded-lg px-2 py-1"
            >
              <span>{s.icon}</span>
              {s.label}
            </span>
          ))}
        </div>

        <div className="flex items-center gap-1.5 pt-2 border-t border-gray-border">
          <span
            className="w-[18px] h-[18px] rounded-full flex items-center justify-center text-[9px] font-bold text-white"
            style={{ background: authorAvatarColor }}
          >
            {authorName.charAt(0) || '?'}
          </span>
          <span className="text-[11px] text-text-600">{authorName}</span>
        </div>
      </div>
    </article>
  );
}
