# 냉장고 셰프 AI (Fridge Chef AI)

냉장고 사진을 찍거나 갤러리에서 선택하면 AI가 식재료를 인식하고, 보유한 재료와 기본 양념을 바탕으로 **지금 바로 만들 수 있는 요리**와 **조금만 추가하면 가능한 요리**를 추천해 주는 Flutter 모바일 앱입니다.

## 주요 문서
- [PROJECT_BRIEF.md](./PROJECT_BRIEF.md) — 제품 목표 및 핵심 요구사항
- [ARCHITECTURE.md](./ARCHITECTURE.md) — 기술 스택, 폴더 구조 및 데이터 흐름
- [DECISIONS.md](./DECISIONS.md) — 주요 설계 및 기술 의사결정 기록
- [ROADMAP.md](./ROADMAP.md) — 단계별 개발 계획 및 진행 현황
- [TEST_PLAN.md](./TEST_PLAN.md) — 단위/위젯/통합 테스트 및 MVP 완료 기준

## 개발 환경 및 실행 방법

### 1. 필수 SDK
- Flutter SDK (Stable 3.x 이상)
- Android SDK / Android CLI (Android 빌드 및 실행용)
- Xcode (macOS에서 iOS 빌드 및 시뮬레이터 실행 시 필요)

### 2. 의존성 설치 및 실행
```bash
# 패키지 설치
flutter pub get

# 정적 분석 실행
dart analyze lib test

# 전체 테스트 실행 (단위 테스트 + E2E 위젯 플로우 테스트 9종)
flutter test

# 앱 실행 (기본 모드 / 스마트 데모 AI 포함)
flutter run

# 실제 Gemini API 키를 런타임 주입하여 실행할 경우 (코드에 키를 저장하지 않음)
flutter run --dart-define=GEMINI_API_KEY=your_api_key_here

# Android APK 빌드
flutter build apk --debug
```

### 3. iOS 빌드 환경 안내 (macOS)
- Android 우선 출시 기준 MVP가 완성되어 있으며, 동일한 코드베이스(`lib/`)로 iOS를 즉시 지원합니다.
- iOS 시뮬레이터 실행 또는 IPA 빌드를 진행할 때는 macOS App Store에서 정식 **Xcode.app** 및 **CocoaPods**(`brew install cocoapods`)를 설치한 후 `flutter build ios`를 실행하세요.
