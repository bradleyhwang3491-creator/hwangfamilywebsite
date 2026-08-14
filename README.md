# 황이서네 가족 라이프로그 (프로토타입)

가족의 여행 · 러닝 · 골프 · 헬스 기록을 남기는 모바일 우선 웹앱(PWA) 프로토타입입니다.
디자인 규칙은 [`DESIGN_SYSTEM.md`](./DESIGN_SYSTEM.md) 를 따릅니다.

## 이번 단계에서 만든 것
1. **로그인 화면** (`/login`) — 아이디/비밀번호 입력 + 로그인 시 문자 발송 2FA(6자리) 인증 모달
   - 데모 인증번호: `123456` (실제 SMS 발송은 아직 연동 전, 프로토타입용 하드코딩)
2. **로그인 이후 홈 화면** (`/home`) — 가족 활동 피드 대시보드 + 하단 고정 네비게이션 바
   - `/travel`, `/activity`, `/my` 는 다음 단계 작업을 위한 자리표시(placeholder) 화면입니다.

## 기술 스택
- React 19 + TypeScript + Vite
- Tailwind CSS v4 (`@tailwindcss/vite`)
- react-router-dom (클라이언트 라우팅)
- Pretendard Variable (CDN, `index.html`에 로드)

## 실행 방법
```bash
npm install
npm run dev       # 개발 서버 (기본 http://localhost:5173)
npm run build     # 프로덕션 빌드
npm run preview   # 빌드 결과 미리보기
```
모바일 화면 확인은 브라우저 개발자도구의 반응형 모드(iPhone 12/13 Pro 등, 390×844)에서 확인하는 것을 권장합니다.

## 폴더 구조
```
src/
  components/     # BottomNav, FeedCard, OtpModal 등 공통 컴포넌트
  pages/          # LoginPage, HomePage, PlaceholderPage
  data/           # 목업 데이터 (카테고리 메타, 피드 데이터)
  types/          # 공용 타입 정의
  index.css       # Tailwind + 디자인 토큰(CSS 변수)
DESIGN_SYSTEM.md  # 전체 프로젝트 디자인 가이드
```

## 다음 단계 (예정)
- **Supabase 연동**: Auth(아이디/비밀번호 + 문자 OTP), DB 스키마(가족/멤버/여행/운동 기록), Storage(사진 업로드)
  - `.env.example` 참고하여 `.env.local`에 `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY` 설정 예정
- **Vercel 배포**: `vercel.json` 및 GitHub 연동 배포 파이프라인 구성 예정
- **Git 형상관리**: 저장소 생성 후 브랜치 전략 안내 예정
- 여행 기록(등록/블로그), 운동 기록(러닝/골프/헬스) 상세 화면 구현
