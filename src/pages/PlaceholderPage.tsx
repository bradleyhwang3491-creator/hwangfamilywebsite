import BottomNav from '../components/BottomNav';

export default function PlaceholderPage({ title, emoji }: { title: string; emoji: string }) {
  return (
    <div className="app-frame">
      <header className="safe-top px-5 pt-4 pb-3 bg-white border-b border-gray-border">
        <h1 className="text-[20px] font-bold text-text-900">{title}</h1>
      </header>
      <main className="flex-1 flex flex-col items-center justify-center px-5 pb-24 text-center">
        <div className="text-5xl mb-4">{emoji}</div>
        <h2 className="text-[17px] font-semibold text-text-900 mb-1.5">준비 중인 화면이에요</h2>
        <p className="text-[13px] text-text-400 leading-relaxed">
          다음 단계에서 {title} 기능을 만들 예정입니다.
        </p>
      </main>
      <BottomNav />
    </div>
  );
}
