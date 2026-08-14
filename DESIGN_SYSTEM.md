# DESIGN_SYSTEM.md
### 황이서네 가족 라이프로그 — Family Activity Life Log
**버전**: v1.0 &nbsp;|&nbsp; **최종 수정일**: 2026-08-14 &nbsp;|&nbsp; **적용 범위**: 전체 페이지 · 전체 컴포넌트

> 이 문서는 여행 · 러닝 · 골프 · 헬스 등 가족의 액티비티 기록을 담는 모바일 우선 웹앱(PWA)의
> UI/UX 및 디자인 규칙을 정의한다. 모든 화면과 컴포넌트는 이 문서를 기준으로 제작한다.

---

## 1. 디자인 원칙 (Design Principles)

| 원칙 | 설명 |
|---|---|
| **Mobile-First** | iOS/Android 브라우저 기준으로 먼저 설계하고, 데스크톱은 모바일 프레임을 중앙에 유지한다. |
| **Clean White & Minimalist** | 여백을 충분히 두고 컬러는 절제하여, 사진(가족의 기록)이 주인공이 되도록 한다. |
| **Warm but Trustworthy** | Primary는 신뢰감(딥 블루), Accent는 온기(오렌지/그린) — 정보 앱이 아닌 "우리 가족 다이어리" 톤. |
| **One-hand Usability** | 주요 액션(등록, 탭 이동)은 엄지가 닿는 화면 하단부에 배치한다. |
| **Consistency over Novelty** | 화면마다 다른 스타일을 시도하지 않는다. 아래 토큰만 조합해서 사용한다. |

---

## 2. 컬러 팔레트 (Color Palette)

### 2.1 Base
| 이름 | 역할 | Hex |
|---|---|---|
| `white` | 기본 배경, 카드 표면 | `#FFFFFF` |
| `gray-bg` | 섹션 배경, 앱 전체 배경 | `#F8F9FA` |
| `gray-border` | 카드/구분선 테두리 | `#F1F3F5` |
| `gray-100` | 비활성 배경, 뱃지 배경 | `#F1F5F9` |

### 2.2 Text
| 이름 | 역할 | Hex |
|---|---|---|
| `text-900` | 제목, 강조 텍스트 | `#111827` |
| `text-600` | 본문 텍스트 | `#4B5563` |
| `text-400` | 보조 설명, placeholder | `#9CA3AF` |
| `text-inverse` | 컬러 배경 위 텍스트 | `#FFFFFF` |

### 2.3 Primary (신뢰 · 브랜드)
| 이름 | 역할 | Hex |
|---|---|---|
| `primary-600` | 기본 버튼, 링크, 활성 탭 | `#2563EB` |
| `primary-700` | 버튼 hover/active, 강조 텍스트 | `#1E40AF` |
| `primary-50` | 연한 배경(뱃지, 선택 상태) | `#EFF6FF` |

### 2.4 Accent (포인트)
| 이름 | 역할 | Hex |
|---|---|---|
| `accent-orange` | 여행/온기 포인트, 알림 dot | `#F97316` |
| `accent-orange-bg` | 오렌지 뱃지 배경 | `#FFF7ED` |
| `accent-green` | 성공/운동완료/헬스 포인트 | `#10B981` |
| `accent-green-bg` | 그린 뱃지 배경 | `#ECFDF5` |

### 2.5 Semantic
| 이름 | 역할 | Hex |
|---|---|---|
| `danger` | 에러, 삭제, 인증 실패 | `#EF4444` |
| `warning` | 타이머 임박, 주의 | `#F59E0B` |
| `success` | 저장 완료 토스트 | `#10B981` |

### 2.6 액티비티별 뱃지 컬러 (카테고리 컬러 코딩)
> 홈 피드/카드에서 어떤 활동인지 한눈에 구분하기 위한 고정 컬러. 아이콘·뱃지에만 사용하고 배경 전체에는 사용하지 않는다.

| 카테고리 | 컬러 | 배경 |
|---|---|---|
| ✈️ 여행 | `#F97316` (Orange) | `#FFF7ED` |
| 🏃 러닝 | `#2563EB` (Blue) | `#EFF6FF` |
| ⛳ 골프 | `#10B981` (Green) | `#ECFDF5` |
| 💪 헬스 | `#7C3AED` (Violet) | `#F5F3FF` |

---

## 3. 타이포그래피 (Typography)

### 3.1 폰트 패밀리
```css
font-family: 'Pretendard Variable', Pretendard, -apple-system, BlinkMacSystemFont,
             system-ui, Roboto, sans-serif;
```
- CDN(개발용): `https://cdn.jsdelivr.net/gh/orioncactus/pretendard/dist/web/variable/pretendardvariable-dynamic-subset.css`
- 배포 시에는 self-host(woff2) 권장 (FOUT 방지, 성능).

### 3.2 타입 스케일
| 토큰 | 크기/줄간격 | Weight | 용도 |
|---|---|---|---|
| `display` | 28px / 36px | 700 | 온보딩·로그인 타이틀 |
| `h1` | 22px / 30px | 700 | 페이지 타이틀 (예: "여행 기록") |
| `h2` | 18px / 26px | 600 | 섹션 타이틀, 카드 제목 |
| `h3` | 16px / 24px | 600 | 리스트 아이템 제목 |
| `body` | 15px / 22px | 400 | 기본 본문 |
| `body-medium` | 15px / 22px | 500 | 강조 본문(버튼 라벨 등) |
| `caption` | 13px / 18px | 400 | 보조 설명, 타임스탬프 |
| `chip` | 12px / 16px | 600 | 뱃지, 스탯 칩 텍스트 |

### 3.3 Font Weight 사용 규칙
| Weight | 값 | 사용처 |
|---|---|---|
| Regular | 400 | 본문, 설명 텍스트 |
| Medium | 500 | 버튼, 강조 라벨, input 값 |
| SemiBold | 600 | 카드 타이틀, 섹션 헤더, 뱃지 |
| Bold | 700 | 페이지 타이틀, 숫자 강조(스탯) |

---

## 4. 레이아웃 & 스페이싱 (Layout & Spacing)

### 4.1 그리드 & 뷰포트
- **Max-width**: `480px`, 화면 중앙 정렬(`margin: 0 auto`). 480px 이상 뷰포트(데스크톱)에서는 좌우에 `gray-bg` 여백을 채워 "모바일 프레임" 느낌을 유지.
- **Safe Area**: `env(safe-area-inset-*)`를 상단/하단 padding에 반영 (노치, 홈 인디케이터 대응).
- **가로 패딩(Screen Padding)**: `20px` 고정.

### 4.2 스페이싱 스케일 (4px 기반)
| 토큰 | 값 |
|---|---|
| `space-1` | 4px |
| `space-2` | 8px |
| `space-3` | 12px |
| `space-4` | 16px |
| `space-5` | 20px |
| `space-6` | 24px |
| `space-8` | 32px |
| `space-10` | 40px |

### 4.3 Radius
| 토큰 | 값 | 용도 |
|---|---|---|
| `radius-sm` | 8px | 뱃지, 칩, input |
| `radius-md` | 12px | 버튼, 작은 카드 |
| `radius-lg` | 16px | 메인 카드, 모달 |
| `radius-xl` | 24px | 바텀시트 상단, 히어로 카드 |
| `radius-full` | 999px | 아바타, 원형 버튼, pill 뱃지 |

### 4.4 Elevation (Shadow)
| 토큰 | 값 | 용도 |
|---|---|---|
| `shadow-card` | `0 1px 2px rgba(16,24,40,0.04), 0 1px 3px rgba(16,24,40,0.06)` | 기본 카드 |
| `shadow-float` | `0 8px 24px rgba(16,24,40,0.10)` | FAB, 바텀 네비, 모달 |
| `shadow-modal` | `0 20px 40px rgba(16,24,40,0.18)` | 풀스크린 모달, 바텀시트 |

카드는 그림자보다 `1px solid #F1F3F5` 테두리를 1차 구분자로 사용하고, 그림자는 보조적으로만(옅게) 적용한다.

---

## 5. 공통 컴포넌트 스펙 (Component Spec)

### 5.1 Button
| 종류 | 배경 | 텍스트 | 높이 | Radius | 사용처 |
|---|---|---|---|---|---|
| Primary | `primary-600` (active: `primary-700`) | white / 500 | 52px | `radius-md` | 로그인, 저장, 주요 CTA |
| Secondary | white + border `gray-border` | `text-900` / 500 | 52px | `radius-md` | 취소, 보조 액션 |
| Ghost/Text | transparent | `primary-600` / 500 | 44px | - | 링크형 액션("다시 받기") |
| Danger | white + border `danger` | `danger` / 500 | 52px | `radius-md` | 삭제, 로그아웃 |
| Disabled | `gray-100` | `text-400` | 52px | `radius-md` | 조건 미충족 시 |

- 전체 너비(`width: 100%`) 버튼이 기본. 화면 하단 고정 CTA는 `padding-bottom: safe-area + 16px`.
- 버튼 텍스트는 동사형("저장하기", "인증하기")로 명확하게.

### 5.2 Input / Form Field
```
Label (13px, 600, text-600)
┌──────────────────────────────┐
│  Input value / Placeholder     │  height 52px, radius-md, border 1px gray-border
└──────────────────────────────┘
Helper / Error text (12px)
```
- 기본 테두리: `#E5E7EB` → focus 시 `primary-600` 2px + `primary-50` 은은한 outline.
- 에러 상태: 테두리 `danger`, 하단에 에러 메시지(`danger`, 12px) 노출.
- 패딩: 좌우 16px.
- Placeholder 컬러: `text-400`.

### 5.3 Card (Base)
- 배경 `white`, 테두리 `1px solid gray-border`, radius `radius-lg`(16px), 내부 패딩 `16px`.
- 그림자 `shadow-card`.
- 카드 간 세로 간격: `12px`.

**Life-log Feed Card (홈 화면)**
```
┌───────────────────────────────────────┐
│ [썸네일 이미지 16:10]                     │
│                                         │
│ 🏷 카테고리뱃지     🕒 3시간 전            │
│ 제목 (h3, 600)                          │
│ 요약 설명 1~2줄 (body, text-600)          │
│ [스탯칩] [스탯칩] [스탯칩]                 │
│ ── ── ── ── ── ── ── ── ── ── ──        │
│ 👤 참여 가족 아바타(겹침)   ❤️ 좋아요 12    │
└───────────────────────────────────────┘
```

**Magazine/Blog Card (여행 기록)**
- 이미지 비율 4:3 또는 정방형, 다중 이미지는 우측 상단에 `+3` 카운트 오버레이.
- 타이틀은 h2(18/600), 아래 위치·날짜를 caption으로.

### 5.4 Badge & Stat Chip
- **카테고리 뱃지**: `radius-full`, 패딩 `4px 10px`, `chip`(12/600), 배경은 §2.6 카테고리 컬러의 연한 버전, 텍스트는 진한 버전.
- **스탯 칩**(거리, 타수, 세트수 등): 아이콘 + 값 + 단위. 배경 `gray-100`, radius `radius-sm`, 패딩 `6px 10px`, 텍스트 `text-900`/600, 아이콘은 카테고리 컬러.
  - 예) `🏃 5.2 km` `⏱ 28:14` `⛳ 82타` `💪 스쿼트 5세트`

### 5.5 Bottom Navigation Bar (Fixed)
- 높이: `64px` + `safe-area-inset-bottom`.
- 배경: `white`, 상단 `1px solid gray-border`, `shadow-float`(위쪽 방향).
- `position: fixed; bottom: 0;` max-width 480px 컨테이너 안에서 고정.
- 탭 4~5개, 아이콘(24px) + 라벨(11px/500).
- 활성 탭: 아이콘/텍스트 `primary-600` + 아이콘 위 2px dot 또는 채워진 아이콘. 비활성: `text-400`.
- 중앙에 "기록 추가" FAB(원형, `primary-600`, `+`아이콘, 56px, `shadow-float`)를 살짝 띄워서(‑12px) 배치 가능(선택 옵션).

```
┌──────┬──────┬──(＋)──┬──────┬──────┐
│ 홈    │ 여행  │  기록추가 │ 운동  │ MY   │
└──────┴──────┴────────┴──────┴──────┘
```

### 5.6 2FA / OTP Modal (인증 UI 패턴)
- **트리거**: ID/PW 검증 성공 시 하단에서 올라오는 바텀시트(모바일) 또는 중앙 모달(데스크톱).
- **구성 요소**
  1. 안내 텍스트: "010-****-1234 로 전송된 인증번호 6자리를 입력해주세요" (body, text-600)
  2. **6칸 PIN 입력 UI**: 정사각형 박스 6개(각 44×52px, radius-sm, border gray-border), 숫자 입력 시 자동 다음 칸 이동, 커서 칸은 `primary-600` 테두리 강조. 전체를 하나의 `inputmode="numeric"` 필드로 구현하고 시각적으로만 6칸 분리.
  3. **타이머**: `3:00`부터 카운트다운(mm:ss), `warning` 컬러로 30초 이하일 때 강조, PIN 입력 필드 우측 또는 하단에 배치.
  4. **재전송 링크**: "인증번호 재전송" (Ghost 버튼), 타이머 만료 전까지 비활성(`text-400`) → 만료 시 `primary-600` 활성화.
  5. 에러 시: 6칸 테두리 `danger` + shake 애니메이션(150ms) + 하단 에러 문구.
  6. 하단 CTA: "인증하기" Primary 버튼, 6자리 모두 입력 전까지 Disabled.
- 모달 radius: `radius-xl`(상단만), 배경 dim `rgba(17,24,39,0.4)`.

### 5.7 Toast / Empty State
- Toast: 화면 하단(바텀 네비 위), `text-900` 배경 + white 텍스트, radius `radius-md`, 2.5초 후 자동 소멸.
- Empty state: 중앙 정렬 일러스트/이모지 + "아직 기록이 없어요" (h3) + "가족과의 첫 기록을 남겨보세요" (caption) + Primary 버튼.

---

## 6. 모션 (Motion)
- 기본 전환: `150–200ms ease-out`.
- 페이지 전환: 좌→우 슬라이드(하위 메뉴 진입), 모달/바텀시트는 아래→위 슬라이드 250ms.
- 과한 모션 지양 — 리스트 스크롤 시 stagger 애니메이션 등은 사용하지 않는다(성능/일관성).
- `prefers-reduced-motion` 대응: 모션 대신 fade만 적용.

---

## 7. 접근성 & 반응형 규칙
- 터치 타겟 최소 `44×44px`.
- 포커스 시 시각적 outline 유지(키보드 접근성).
- 명도 대비 WCAG AA 이상 (본문 텍스트 `text-600` on white ≥ 4.5:1).
- 480px 이상 화면에서는 모바일 프레임 바깥 영역을 `gray-bg`로 채우고, 프레임에는 `shadow-modal`을 옅게 주어 "디바이스" 느낌 부여(선택).

---

## 8. 디자인 토큰 (CSS Variables 참조용)

```css
:root {
  /* Color */
  --color-white: #FFFFFF;
  --color-gray-bg: #F8F9FA;
  --color-gray-border: #F1F3F5;
  --color-gray-100: #F1F5F9;

  --color-text-900: #111827;
  --color-text-600: #4B5563;
  --color-text-400: #9CA3AF;

  --color-primary-600: #2563EB;
  --color-primary-700: #1E40AF;
  --color-primary-50: #EFF6FF;

  --color-accent-orange: #F97316;
  --color-accent-orange-bg: #FFF7ED;
  --color-accent-green: #10B981;
  --color-accent-green-bg: #ECFDF5;

  --color-danger: #EF4444;
  --color-warning: #F59E0B;
  --color-success: #10B981;

  /* Radius */
  --radius-sm: 8px;
  --radius-md: 12px;
  --radius-lg: 16px;
  --radius-xl: 24px;
  --radius-full: 999px;

  /* Spacing */
  --space-1: 4px;  --space-2: 8px;  --space-3: 12px; --space-4: 16px;
  --space-5: 20px; --space-6: 24px; --space-8: 32px; --space-10: 40px;

  /* Shadow */
  --shadow-card: 0 1px 2px rgba(16,24,40,.04), 0 1px 3px rgba(16,24,40,.06);
  --shadow-float: 0 8px 24px rgba(16,24,40,.10);
  --shadow-modal: 0 20px 40px rgba(16,24,40,.18);

  /* Layout */
  --app-max-width: 480px;
  --bottom-nav-height: 64px;
}
```

---

## 9. 화면별 적용 체크리스트

| 화면 | 적용 규칙 |
|---|---|
| 로그인/2FA | §5.2 Input, §5.6 OTP Modal, §5.1 Primary Button |
| 홈(피드) | §5.3 Life-log Feed Card, §2.6 카테고리 컬러, §5.5 Bottom Nav |
| 여행 등록/블로그 | §5.3 Magazine Card, 다중 이미지 그리드(2×2 또는 가로 스크롤) |
| 러닝/골프/헬스 | §5.4 Stat Chip(종목별 지표), §2.6 카테고리 컬러 뱃지 |

---

*이 문서는 프로젝트 진행에 따라 갱신된다. 컴포넌트를 새로 추가할 때는 반드시 본 문서의 토큰(컬러/타입/스페이싱)을 재사용하고, 새 값이 필요하면 이 문서에 먼저 등록한 뒤 사용한다.*
