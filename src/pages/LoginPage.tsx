import { useState, type FormEvent } from 'react';
import { useNavigate } from 'react-router-dom';
import OtpModal from '../components/OtpModal';

export default function LoginPage() {
  const navigate = useNavigate();
  const [userId, setUserId] = useState('');
  const [password, setPassword] = useState('');
  const [idTouched, setIdTouched] = useState(false);
  const [pwTouched, setPwTouched] = useState(false);
  const [loading, setLoading] = useState(false);
  const [loginError, setLoginError] = useState<string | null>(null);
  const [showOtp, setShowOtp] = useState(false);

  const idValid = userId.trim().length > 0;
  const pwValid = password.length >= 4;
  const formValid = idValid && pwValid;

  function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setIdTouched(true);
    setPwTouched(true);
    if (!formValid) return;

    setLoginError(null);
    setLoading(true);
    // 프로토타입: 실제 인증은 추후 Supabase Auth 연동
    setTimeout(() => {
      setLoading(false);
      setShowOtp(true);
    }, 600);
  }

  function handleVerified() {
    setShowOtp(false);
    navigate('/home');
  }

  return (
    <div className="app-frame">
      <div className="flex-1 flex flex-col px-6 safe-top">
        {/* Brand */}
        <div className="pt-16 pb-10">
          <div
            className="w-14 h-14 rounded-2xl flex items-center justify-center text-2xl mb-5"
            style={{ background: '#EFF6FF' }}
          >
            🏡
          </div>
          <h1 className="text-[28px] font-bold text-text-900 leading-tight mb-2">
            황이서네
            <br />
            가족 라이프로그
          </h1>
          <p className="text-[15px] text-text-600">
            여행, 러닝, 골프, 헬스 — 우리 가족의 하루를 기록해요.
          </p>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="flex flex-col gap-4" noValidate>
          <div>
            <label htmlFor="userId" className="block text-[13px] font-semibold text-text-600 mb-1.5">
              아이디
            </label>
            <input
              id="userId"
              type="text"
              inputMode="email"
              autoComplete="username"
              placeholder="아이디를 입력하세요"
              value={userId}
              onChange={(e) => setUserId(e.target.value)}
              onBlur={() => setIdTouched(true)}
              className="w-full h-13 px-4 rounded-xl border text-[15px] text-text-900 placeholder:text-text-400"
              style={{
                height: 52,
                borderColor: idTouched && !idValid ? '#EF4444' : '#E5E7EB',
                borderWidth: idTouched && !idValid ? 2 : 1,
              }}
            />
            {idTouched && !idValid && (
              <p className="text-[12px] mt-1.5" style={{ color: '#EF4444' }}>
                아이디를 입력해주세요.
              </p>
            )}
          </div>

          <div>
            <label htmlFor="password" className="block text-[13px] font-semibold text-text-600 mb-1.5">
              비밀번호
            </label>
            <input
              id="password"
              type="password"
              autoComplete="current-password"
              placeholder="비밀번호를 입력하세요"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              onBlur={() => setPwTouched(true)}
              className="w-full h-13 px-4 rounded-xl border text-[15px] text-text-900 placeholder:text-text-400"
              style={{
                height: 52,
                borderColor: pwTouched && !pwValid ? '#EF4444' : '#E5E7EB',
                borderWidth: pwTouched && !pwValid ? 2 : 1,
              }}
            />
            {pwTouched && !pwValid && (
              <p className="text-[12px] mt-1.5" style={{ color: '#EF4444' }}>
                비밀번호는 4자 이상 입력해주세요.
              </p>
            )}
          </div>

          <div className="flex justify-end -mt-1">
            <button type="button" className="text-[13px] font-medium" style={{ color: '#4B5563' }}>
              아이디/비밀번호 찾기
            </button>
          </div>

          {loginError && (
            <p className="text-[13px] text-center" style={{ color: '#EF4444' }}>
              {loginError}
            </p>
          )}

          <button
            type="submit"
            disabled={loading}
            className="w-full h-13 rounded-xl text-white font-medium text-[15px] mt-2"
            style={{ height: 52, background: loading ? '#93B6F4' : '#2563EB' }}
          >
            {loading ? '확인 중...' : '로그인'}
          </button>
        </form>

        <div className="flex items-center gap-3 my-7">
          <div className="flex-1 h-px bg-gray-border" />
          <span className="text-[12px] text-text-400">또는</span>
          <div className="flex-1 h-px bg-gray-border" />
        </div>

        <button
          type="button"
          className="w-full h-13 rounded-xl font-medium text-[15px] border"
          style={{ height: 52, borderColor: '#F1F3F5', color: '#111827' }}
        >
          가족 초대 코드로 가입하기
        </button>

        <p className="text-center text-[12px] text-text-400 mt-6 mb-8">
          로그인 시 문자로 전송되는 인증번호(2FA) 확인이 필요합니다.
        </p>
      </div>

      {showOtp && (
        <OtpModal
          phoneNumber="010-****-1234"
          onClose={() => setShowOtp(false)}
          onVerified={handleVerified}
        />
      )}
    </div>
  );
}
