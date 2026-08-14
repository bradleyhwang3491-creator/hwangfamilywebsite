import { BrowserRouter, Navigate, Route, Routes, useLocation } from 'react-router-dom';
import LoginPage from './pages/LoginPage';
import HomePage from './pages/HomePage';
import TravelPage from './pages/TravelPage';
import TravelRecordFormPage from './pages/TravelRecordFormPage';
import TravelRecordDetailPage from './pages/TravelRecordDetailPage';
import PlaceholderPage from './pages/PlaceholderPage';

function AnimatedRoutes() {
  const location = useLocation();

  return (
    <div key={location.pathname} className="animate-page-enter">
      <Routes location={location}>
        <Route path="/" element={<Navigate to="/login" replace />} />
        <Route path="/login" element={<LoginPage />} />
        <Route path="/home" element={<HomePage />} />
        <Route path="/travel" element={<TravelPage />} />
        <Route path="/travel/new" element={<TravelRecordFormPage />} />
        <Route path="/travel/record/:id" element={<TravelRecordDetailPage />} />
        <Route path="/running" element={<PlaceholderPage title="러닝 기록" emoji="🏃" />} />
        <Route path="/golf" element={<PlaceholderPage title="골프 기록" emoji="⛳" />} />
        <Route path="/gym" element={<PlaceholderPage title="헬스 기록" emoji="💪" />} />
        <Route path="/my" element={<PlaceholderPage title="MY" emoji="👤" />} />
        <Route path="*" element={<Navigate to="/login" replace />} />
      </Routes>
    </div>
  );
}

export default function App() {
  return (
    <BrowserRouter>
      <AnimatedRoutes />
    </BrowserRouter>
  );
}
