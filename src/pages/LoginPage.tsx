import { useState, type FormEvent } from 'react';
import { useNavigate } from 'react-router-dom';
import { supabase } from '../lib/supabaseClient';
import { saveSession } from '../lib/session';
import type { AuthUser } from '../types';
import familyHero from '../assets/family-hero.jpg';

export default function LoginPage() {
  const navigate = useNavigate();
  const [userId, setUserId] = useState('');
  const [password, setPassword] = useState('');
  const [idTouched, setIdTouched] = useState(false);
  const [pwTouched, setPwTouched] = useState(false);
  const [loading, setLoading] = useState(false);
  const [loginError, setLoginError] = useState<string | null>(null);

  const idValid = userId.trim().length > 0;
  const pwValid = password.length >= 4;
  const formValid = idValid && pwValid;

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setIdTouched(true);
    setPwTouched(true);
    if (!formValid) return;

    setLoginError(null);
    setLoading(true);

    const { data, error } = await supabase.rpc('login', {
      p_username: userId.trim(),
      p_password: password,
    });

    setLoading(false);

    if (error) {
      setLoginError('로그인 중 오류가 발생했습니다. 잠시 후 다시 시도해주세요.');
      return;
    }

    const user = data?.[0] as AuthUser | undefined;
    if (!user) {
      setLoginError('아이디 또는 비밀번호가 올바르지 않습니다.');
      return;
    }

    saveSession(user);
    navigate('/home');
  }

  return (
    <div className="app-frame">
      <div className="px-5 pt-6">
        <img
          src={familyHero}
          alt="황이서네 가족"
          className="w-full h-48 object-cover rounded-3xl"
          style={{ boxShadow: 'var(--shadow-card)' }}
        />
      </div>
      <div className="flex-1 flex flex-col px-6 pt-6">
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
                borderColor: idTouched && !idValid ? '#111827' : '#E5E7EB',
                borderWidth: idTouched && !idValid ? 2 : 1,
              }}
            />
            {idTouched && !idValid && (
              <p className="text-[12px] mt-1.5 font-semibold" style={{ color: '#111827' }}>
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
                borderColor: pwTouched && !pwValid ? '#111827' : '#E5E7EB',
                borderWidth: pwTouched && !pwValid ? 2 : 1,
              }}
            />
            {pwTouched && !pwValid && (
              <p className="text-[12px] mt-1.5 font-semibold" style={{ color: '#111827' }}>
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
            <p className="text-[13px] text-center font-semibold" style={{ color: '#111827' }}>
              {loginError}
            </p>
          )}

          <button
            type="submit"
            disabled={loading}
            className="w-full h-13 rounded-xl text-white font-medium text-[15px] mt-2"
            style={{ height: 52, background: loading ? '#9CA3AF' : '#111827' }}
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
      </div>
    </div>
  );
}
