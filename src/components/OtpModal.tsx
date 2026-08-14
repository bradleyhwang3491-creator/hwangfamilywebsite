import { useEffect, useRef, useState } from 'react';

interface OtpModalProps {
  phoneNumber: string;
  onClose: () => void;
  onVerified: () => void;
}

const CODE_LENGTH = 6;
const TIMER_SECONDS = 180;
const DEMO_CODE = '123456'; // 프로토타입 데모용 정답 코드

export default function OtpModal({ phoneNumber, onClose, onVerified }: OtpModalProps) {
  const [code, setCode] = useState('');
  const [secondsLeft, setSecondsLeft] = useState(TIMER_SECONDS);
  const [error, setError] = useState<string | null>(null);
  const [shake, setShake] = useState(false);
  const [verifying, setVerifying] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    inputRef.current?.focus();
  }, []);

  useEffect(() => {
    if (secondsLeft <= 0) return;
    const timer = setInterval(() => setSecondsLeft((s) => s - 1), 1000);
    return () => clearInterval(timer);
  }, [secondsLeft]);

  const mm = String(Math.floor(secondsLeft / 60)).padStart(2, '0');
  const ss = String(secondsLeft % 60).padStart(2, '0');
  const expired = secondsLeft <= 0;
  const timerUrgent = secondsLeft <= 30 && secondsLeft > 0;

  function handleChange(v: string) {
    const digits = v.replace(/\D/g, '').slice(0, CODE_LENGTH);
    setCode(digits);
    setError(null);
  }

  function handleResend() {
    setCode('');
    setError(null);
    setSecondsLeft(TIMER_SECONDS);
    inputRef.current?.focus();
  }

  function handleVerify() {
    if (code.length !== CODE_LENGTH || expired) return;
    setVerifying(true);
    setTimeout(() => {
      setVerifying(false);
      if (code === DEMO_CODE) {
        onVerified();
      } else {
        setError('인증번호가 올바르지 않습니다. 다시 확인해주세요.');
        setShake(true);
        setCode('');
        setTimeout(() => setShake(false), 400);
        inputRef.current?.focus();
      }
    }, 500);
  }

  return (
    <div className="absolute inset-0 z-30 flex items-end">
      {/* dim background */}
      <button
        aria-label="닫기"
        onClick={onClose}
        className="absolute inset-0 bg-black/40 animate-fade-in"
      />

      {/* bottom sheet */}
      <div
        className="relative w-full bg-white rounded-t-3xl px-5 pt-3 pb-6 safe-bottom animate-sheet-up"
        style={{ boxShadow: 'var(--shadow-modal)' }}
      >
        <div className="w-10 h-1.5 rounded-full bg-gray-100 mx-auto mb-5" />

        <h2 className="text-[19px] font-bold text-text-900 mb-2">문자 인증</h2>
        <p className="text-[14px] text-text-600 leading-relaxed mb-5">
          <strong className="text-text-900 font-semibold">{phoneNumber}</strong> 로 전송된
          <br />
          인증번호 6자리를 입력해주세요.
        </p>

        {/* hidden real input driving the visual boxes */}
        <div className="relative mb-2">
          <input
            ref={inputRef}
            value={code}
            onChange={(e) => handleChange(e.target.value)}
            inputMode="numeric"
            autoComplete="one-time-code"
            maxLength={CODE_LENGTH}
            aria-label="인증번호 6자리"
            className="absolute inset-0 opacity-0 w-full h-full"
            onKeyDown={(e) => {
              if (e.key === 'Enter') handleVerify();
            }}
          />
          <div className={`flex gap-2 justify-between ${shake ? 'animate-shake' : ''}`}>
            {Array.from({ length: CODE_LENGTH }).map((_, i) => {
              const filled = i < code.length;
              const isCursor = i === code.length && !expired;
              return (
                <div
                  key={i}
                  className="flex-1 h-13 rounded-lg border flex items-center justify-center text-[19px] font-semibold"
                  style={{
                    height: 52,
                    borderColor: error ? '#EF4444' : isCursor ? '#2563EB' : '#F1F3F5',
                    borderWidth: isCursor || error ? 2 : 1,
                    color: '#111827',
                    background: '#FFFFFF',
                  }}
                >
                  {filled ? code[i] : ''}
                </div>
              );
            })}
          </div>
        </div>

        <div className="flex items-center justify-between mb-6 mt-2 h-5">
          {error ? (
            <span className="text-[12px]" style={{ color: '#EF4444' }}>
              {error}
            </span>
          ) : (
            <span className="text-[12px] text-text-400">데모 인증번호: 123456</span>
          )}
          <span
            className="text-[13px] font-semibold tabular-nums"
            style={{ color: expired ? '#EF4444' : timerUrgent ? '#F59E0B' : '#4B5563' }}
          >
            {expired ? '시간 만료' : `${mm}:${ss}`}
          </span>
        </div>

        <button
          onClick={handleResend}
          disabled={!expired}
          className="w-full text-center text-[14px] font-medium mb-3"
          style={{ color: expired ? '#2563EB' : '#9CA3AF' }}
        >
          인증번호 재전송
        </button>

        <button
          onClick={handleVerify}
          disabled={code.length !== CODE_LENGTH || expired || verifying}
          className="w-full h-13 rounded-xl text-white font-medium text-[15px] transition-colors"
          style={{
            height: 52,
            background: code.length === CODE_LENGTH && !expired ? '#2563EB' : '#F1F5F9',
            color: code.length === CODE_LENGTH && !expired ? '#FFFFFF' : '#9CA3AF',
          }}
        >
          {verifying ? '확인 중...' : '인증하기'}
        </button>
      </div>
    </div>
  );
}
