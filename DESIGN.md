# DESIGN.md — 냉장고 셰프 AI (Fridge Chef AI) 디자인 시스템

본 문서는 `create-design-md` 및 `baseline-ui`, `fixing-accessibility`, `fixing-motion-performance` 스킬 규칙과 두 가지 Figma Community UI 레퍼런스를 결합하여 정의한 **냉장고 셰프 AI**의 공식 디자인 시스템 명세입니다.

---

## 1. 레퍼런스 및 적용 스킬 스택

### A. Figma UI 레퍼런스
1. **[Food Delivery App (Yamesh_SB)](https://www.figma.com/community/file/1231521889522325040/food-delivery-app)**
   - **핵심 차용 요소**:
     - 수평 스크롤 카테고리 알약형(Pill) 필터 바 (`전체`, `한식`, `양식`, `일식`, `중식`, `동남아` 및 `🎯 메인 재료` 칩)
     - 64×64 라운드 푸드 컨테이너와 한눈에 읽히는 인라인 메타데이터 배지(`🔥 465kcal · 단백질 16.0g · ⏱ 5분`)
     - 직관적인 다크 차콜 캡슐형 인분 조절 스테퍼(`- 1인분 +`)
2. **[Coffee Shop Mobile App Design (JavaGem)](https://www.figma.com/community/file/1116708627748807811/coffee-shop-mobile-app-design)**
   - **핵심 차용 요소**:
     - 상단 **딥 에스프레소/차콜 솔리드 히어로 대시보드(`#1C1917`)** 와 따뜻한 크림 배경(`#F9F6F0`)의 고대비 레이아웃
     - 웜 테라코타/캐러멜 포인트 컬러(`#C67C4E`)와 프레시 허브 그린(`#15803D`)의 조화
     - 우측 하단/인라인 택타일 액션 버튼(`🎯 메인 추천`, `+ 추가`)과 정돈된 영양 성분(탄·단·지·칼로리) 그리드 타일

### B. UI Skills (`ibelick/ui-skills`) 적용 규칙
- **`baseline-ui`**:
  - **No AI-Slop Gradients**: 인위적인 다중 색상 선형 그라데이션 배너를 제거하고, 솔리드 딥 차콜(`#1C1917`) 표면과 미세한 1px 보더(`#EAE4DC`), 명확한 타이포그래피 위계를 사용합니다.
  - **Tabular Figures (`FontFeature.tabularFigures()`)**: 칼로리(`kcal`), 영양 성분(`g`, `mg`), 인분 수(`인분`), 조리 시간(`분`), 재료 활용도(`%`) 등 모든 수치 데이터에 고정폭 숫자(`tabular-nums`)를 적용하여 숫자가 변할 때 레이아웃 흔들림을 방지합니다.
  - **Destructive Action Confirmation**: 보유 식재료 삭제 시 실수로 데이터가 유실되지 않도록 확인 모달(`AlertDialog`)을 제공합니다.
  - **Single Primary CTA on Empty States**: 빈 상태(Empty State) 카드에는 경쟁하는 여러 버튼 대신 명확한 단일 주요 행동 유도 버튼(Primary CTA)을 배치합니다.
- **`fixing-accessibility`**:
  - 모든 아이콘 전용 버튼(`IconButton`)에 명확한 `tooltip` 및 접근성 레이블을 부여합니다.
  - 색상만으로 상태를 구분하지 않고 아이콘(`✓`, `+`, `⚠️`, `🎯`)과 텍스트 배지를 함께 표기합니다.
- **`fixing-motion-performance`**:
  - 과도한 블러(`BackdropFilter`)나 레이아웃을 매 프레임 재계산하는 애니메이션을 배제하고, 가벼운 불투명도/색상 전환만 사용합니다.

---

## 2. 컬러 토큰 (Color Palette)

| 역할 | 토큰명 | Hex | 용도 |
|---|---|---|---|
| **Canvas Background** | `warmCream` | `#F9F6F0` | 앱 전체 기본 배경 (따뜻한 알라바스터/크림 톤) |
| **Elevated Surface** | `surfaceWhite` | `#FFFFFF` | 카드, 바텀시트, 입력 필드 배경 |
| **Hero Dark Surface** | `espressoCharcoal` | `#1C1917` | 홈 상단 다크 히어로 대시보드 & 인분 스테퍼 배경 |
| **Hero Elevated Surface** | `espressoMuted` | `#292524` | 다크 히어로 내부 보조 컨테이너 |
| **Primary Brand (Fresh)** | `primaryGreen` | `#15803D` | '지금 바로 가능' 상태, 주요 액션 버튼 |
| **Primary Brand Tint** | `primaryGreenLight` | `#DCFCE7` | 보유 재료 매칭 배지 및 긍정 상태 배경 |
| **Warm Accent (Terracotta)** | `terracotta` | `#C67C4E` | 카테고리/메인 재료 선택 강조, 히어로 프로모 배지 |
| **Warm Accent Tint** | `terracottaLight` | `#F9F2ED` | 테라코타 선택 칩 배경 및 영양소 강조 타일 |
| **Warning / Missing** | `accentAmberDark` | `#B45309` | 부족한 재료, 수량 미입력 안내 |
| **Danger / Allergy** | `dangerRed` | `#DC2626` | 식재료 삭제, 알레르기 경고, 식품 안전 주의사항 |
| **Border Subtle** | `borderSubtle` | `#EAE4DC` | 카드 및 구분선 1px 보더 |

---

## 3. 타이포그래피 및 숫자 규칙 (Typography & Tabular Numerals)

- **헤드라인 (Screen / Hero Title)**: `20px ~ 22px`, `FontWeight.w800`, `letterSpacing: -0.4`, 줄높이 `1.3`
- **카드 타이틀 (Recipe / Section Title)**: `16.5px ~ 18px`, `FontWeight.w800`, `letterSpacing: -0.3`
- **본문 및 조리 단계 (Body)**: `14px ~ 14.5px`, `FontWeight.w500`, 줄높이 `1.5`
- **수치/메타데이터 (`AppTheme.tabularFigures`)**:
  - `FontFeature.tabularFigures()` 필수 적용
  - 칼로리(`465kcal`), 영양소(`단백질 16.0g`), 조리 시간(`5분`), 인분(`2인분`), 활용도(`100%`)

---

## 4. 핵심 컴포넌트 패턴

1. **히어로 대시보드 카드 (`PantryScreen`)**
   - JavaGem Coffee Shop 레퍼런스의 다크 차콜 헤더(`#1C1917`) + 테라코타 배지(`#C67C4E`) 스타일
   - 보유 재료 수와 바로 가능한 요리 수를 `tabularFigures` 카운터로 표시
2. **수평 알약형(Pill) 필터 바 (`RecommendationScreen`)**
   - Food Delivery 레퍼런스의 라운드 알약형(Radius `999px`) 칩 디자인
   - 요리 카테고리(`전체`, `한식`, `양식`, `일식`, `중식`, `동남아`)와 `🎯 메인 재료 선택` 칩을 직관적으로 분리
3. **고밀도 레시피 카드 (`RecommendationScreen`)**
   - 좌측 64×64 라운드 요리 아이콘 박스 + 상단 상태/카테고리/활용도 배지 + 요리명 + `🔥 kcal · 단백질 g · ⏱ 분` 메타데이터 + 보유/부족 재료 태그
4. **실시간 영양소 & 인분 스테퍼 (`RecipeDetailScreen`)**
   - 인분 조절 시 칼로리·탄수화물·단백질·지방·나트륨이 레이아웃 흔들림 없이 즉시 재계산되는 4열 영양 타일
