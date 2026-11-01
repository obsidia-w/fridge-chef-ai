# ARCHITECTURE.md — 시스템 아키텍처 및 기술 구조

## 1. 아키텍처 원칙
- **관심사 분리 (SoC):** UI(Presentation), 상태 관리(Application/State), 도메인 로직(Domain), 데이터 저장 및 외부 API(Data/Infrastructure)를 명확히 분리한다.
- **Feature-First 모듈화:** 기능 단위로 응집도 높은 디렉터리 구조를 유지하고, 단일 파일이 비대해지지 않도록 관리한다.
- **테스트 가능성 (Testability):** AI 이미지 분석기, 레시피 추천 엔진, 로컬 저장소는 인터페이스(추상 클래스)를 통해 주입하여 네트워크나 실제 디바이스 없이도 단위/위젯 테스트가 가능하도록 설계한다.
- **크로스 플랫폼 호환성:** Android 우선 출시 후 iOS로 즉시 확장할 수 있도록 플랫폼 종속 코드는 권한/파일 처리 어댑터로 격리한다.
- **보안 및 프라이버시:** 모바일 클라이언트 코드에 AI API 키를 하드코딩하지 않는다(Firebase AI Logic 또는 런타임 `--dart-define` 주입). 촬영 사진은 리사이징 후 분석에만 사용하고 영구 보관하지 않는다.

## 2. 기술 스택
- **프레임워크:** Flutter (Dart 3.x)
- **상태 관리 및 DI:** `flutter_riverpod`
- **라우팅:** `go_router`
- **로컬 저장소 (오프라인 지원):** 로컬 영속 저장소 (`shared_preferences` / SQLite 기반 로컬 DB)
- **AI 연동:** Firebase AI Logic (`firebase_ai`) / Gemini 2.5 Flash Structured Output (개발 및 오프라인 테스트를 위한 Mock & `--dart-define` 어댑터 병행 지원)
- **이미지 처리:** `image_picker`, 이미지 리사이징/압축 처리

## 3. 디렉터리 구조
```text
lib/
├── main.dart
├── app.dart
├── core/
│   ├── theme/           # '프레시 키친(옵션 A)' 컬러, 타이포그래피, 디자인 토큰
│   ├── router/          # go_router 설정 및 화면 경로 정의
│   ├── constants/       # 기본 양념 목록, 카테고리, 알레르기 유발 식품 상수
│   ├── error/           # Failure / AppException 정의
│   └── utils/           # 식재료 한국어 동의어 정규화 사전, 단위 계산 유틸
├── features/
│   ├── pantry/          # 식재료 관리 (내 냉장고, 기본 양념장, 오프라인 저장)
│   ├── scanner/         # 사진 촬영/선택, AI 식재료 인식, 검수 및 수정 화면
│   ├── recommendation/  # 규칙 기반 레시피 매칭 엔진 + AI 보조 추천 화면
│   ├── recipe_detail/   # 상세 조리법, 인분 변환기, 식품 안전 가이드, 북마크
│   └── preferences/     # 알레르기, 선호 요리, 조리 시간, 인분 등 사용자 설정
└── shared/
    └── widgets/         # 공통 상태 뷰(로딩, 에러, 빈 목록), 배지, 카드 컴포넌트
```

## 4. 핵심 데이터 흐름
1. **식재료 인식 파이프라인:**
   `ImagePicker` -> 이미지 압축 -> `IngredientScannerService` (Gemini JSON Schema 강제) -> `IngredientNormalizer` (한국어 표준화 및 중복 병합, 비식품 제거) -> 검수 UI (`ReviewScreen`) -> `PantryRepository` 저장.
2. **요리 추천 파이프라인:**
   `PantryRepository` (보유 재료 + 기본 양념) + `PreferencesRepository` (알레르기/시간/난이도) + `RecipeRepository` (검증된 시드 레시피 DB) -> `RecipeRecommendationEngine` (결정론적 규칙 매칭: 100% 가능 vs 1~2개 부족 분류, 알레르기 엄격 배제, 수량 불확실성 플래그) -> 추천 UI 표시.
