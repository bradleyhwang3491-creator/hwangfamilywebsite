import { NavLink } from 'react-router-dom';

interface NavItem {
  to: string;
  label: string;
  icon: (active: boolean) => React.ReactNode;
}

function IconHome({ active }: { active: boolean }) {
  return (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
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

function IconTravel({ active }: { active: boolean }) {
  return (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
      <path
        d="M3 13l7-1 2.5-6.5c.2-.5.9-.6 1.2-.1l.8 1.3L11 13l4 1 5-3 1 1-4 4-6-1-3 3H5l2-3-4-1 0-1z"
        stroke={active ? '#111827' : '#9CA3AF'}
        strokeWidth={active ? 1.8 : 1.5}
        strokeLinejoin="round"
        fill={active ? '#F1F5F9' : 'none'}
      />
    </svg>
  );
}

function IconActivity({ active }: { active: boolean }) {
  return (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
      <path
        d="M3 12h4l2-6 4 12 2-6h6"
        stroke={active ? '#111827' : '#9CA3AF'}
        strokeWidth={active ? 2.2 : 1.8}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}

function IconMy({ active }: { active: boolean }) {
  return (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
      <circle cx="12" cy="8" r="3.4" stroke={active ? '#111827' : '#9CA3AF'} strokeWidth={active ? 2.2 : 1.8} />
      <path
        d="M5 20c1.2-3.6 4-5.4 7-5.4s5.8 1.8 7 5.4"
        stroke={active ? '#111827' : '#9CA3AF'}
        strokeWidth={active ? 2.2 : 1.8}
        strokeLinecap="round"
      />
    </svg>
  );
}

const NAV_ITEMS: NavItem[] = [
  { to: '/home', label: '홈', icon: (a) => <IconHome active={a} /> },
  { to: '/travel', label: '여행', icon: (a) => <IconTravel active={a} /> },
  { to: '/activity', label: '운동', icon: (a) => <IconActivity active={a} /> },
  { to: '/my', label: 'MY', icon: (a) => <IconMy active={a} /> },
];

export default function BottomNav() {
  return (
    <nav
      className="fixed bottom-0 left-1/2 -translate-x-1/2 w-full max-w-[480px] bg-white border-t border-gray-border safe-bottom z-20"
      style={{ boxShadow: 'var(--shadow-float)' }}
    >
      <div className="relative flex items-stretch h-16">
        {NAV_ITEMS.slice(0, 2).map((item) => (
          <NavTab key={item.to} item={item} />
        ))}

        {/* Center FAB - add record */}
        <div className="relative w-0">
          <button
            aria-label="기록 추가"
            className="absolute -top-5 left-1/2 -translate-x-1/2 w-14 h-14 rounded-full flex items-center justify-center text-white text-2xl font-semibold"
            style={{ background: '#111827', boxShadow: 'var(--shadow-float)' }}
          >
            +
          </button>
        </div>

        {NAV_ITEMS.slice(2).map((item) => (
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
