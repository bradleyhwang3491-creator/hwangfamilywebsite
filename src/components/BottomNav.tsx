import { NavLink } from 'react-router-dom';

interface NavItem {
  to: string;
  label: string;
  icon: (active: boolean) => React.ReactNode;
}

function IconHome({ active }: { active: boolean }) {
  return (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none">
      <path
        d="M4 11.5L12 4l8 7.5M6 9.5V19a1 1 0 0 0 1 1h3v-5a2 2 0 1 1 4 0v5h3a1 1 0 0 0 1-1V9.5"
        stroke={active ? '#111827' : '#9CA3AF'}
        strokeWidth={active ? 2.2 : 1.8}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}

const NAV_ITEMS: NavItem[] = [
  { to: '/home', label: '홈', icon: (a) => <IconHome active={a} /> },
  { to: '/travel', label: '여행', icon: () => <span className="text-[19px] leading-none">✈️</span> },
  { to: '/running', label: '러닝', icon: () => <span className="text-[19px] leading-none">🏃</span> },
  { to: '/golf', label: '골프', icon: () => <span className="text-[19px] leading-none">⛳</span> },
  { to: '/gym', label: '헬스', icon: () => <span className="text-[19px] leading-none">💪</span> },
];

export default function BottomNav() {
  return (
    <nav
      className="fixed bottom-0 left-1/2 -translate-x-1/2 w-full max-w-[480px] bg-white border-t border-gray-border safe-bottom z-20"
      style={{ boxShadow: 'var(--shadow-float)' }}
    >
      <div className="flex items-stretch h-16">
        {NAV_ITEMS.map((item) => (
          <NavTab key={item.to} item={item} />
        ))}
      </div>
    </nav>
  );
}

function NavTab({ item }: { item: NavItem }) {
  return (
    <NavLink to={item.to} className="flex-1 flex flex-col items-center justify-center gap-1">
      {({ isActive }) => (
        <>
          {item.icon(isActive)}
          <span
            className="text-[11px] leading-none"
            style={{ color: isActive ? '#111827' : '#9CA3AF', fontWeight: isActive ? 600 : 500 }}
          >
            {item.label}
          </span>
        </>
      )}
    </NavLink>
  );
}
