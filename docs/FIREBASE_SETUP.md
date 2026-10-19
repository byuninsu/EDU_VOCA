# Firebase 구글 로그인 설정

현재 구현은 Android 구글 로그인·로그아웃·Firebase 세션 복원이다.
앱 실행 시 공통 로그인 안내와 Google 공식 아이콘이 있는 버튼을 먼저 표시한다.
Firebase 프로젝트 설정이 없어도 버튼은 유지하며, 버튼을 다시 누르면 연결을 재시도한다.
2026-10-08 최신 확인: `android/app/google-services.json` 및 `lib/firebase_options.dart` 생성 완료.
FirebaseAuthRepository에서 DefaultFirebaseOptions.currentPlatform으로 초기화한다.
최신 JSON 검토 완료: 패키지 com.dailyenglish.edu_voca, Firebase 프로젝트/app ID/API key/sender ID가 Dart 설정과 일치한다.
웹 OAuth 클라이언트 1개 및 디버그 SHA-1과 일치하는 Android OAuth 클라이언트가 있다.
사용자가 Google 공급자 활성화와 SHA-1/SHA-256 등록을 완료했다고 알렸다.
SHA-256의 콘솔 등록 상태 및 실제 기기 로그인은 로컬 JSON 검토만으로 확인하지 않았다.
사용자가 Google 로그인 버튼으로 계정 선택·동의를 진행한다. 기존 세션이 복원되면 홈으로 바로 이동한다.
로그아웃 시 열려 있던 학습·계정 경로를 제거하고 로그인 화면으로 돌아간다. 게스트 진입은 제공하지 않는다.
학습 기록은 기존 `daily_english_v1` 기기 저장소를 유지한다. 로그인은 기록을 업로드하거나
계정별로 분리하지 않는다. Firestore 동기화·기존 기록 이관은 별도 구현이 필요하다.

## 콘솔 설정

1. Firebase 콘솔에서 프로젝트를 만들거나 기존 프로젝트를 선택한다.
2. Android 앱을 등록한다. 패키지 이름은 **com.dailyenglish.edu_voca**다.
3. 프로젝트 설정에 실제 설치할 APK 서명 인증서의 SHA-1 및 SHA-256을 등록한다.
   디버그와 릴리스 키가 다르면 각각 등록한다. Play 배포 시 Play 앱 서명 인증서도 등록한다.
   로컬 디버그 지문은 Android 폴더에서 `./gradlew signingReport`로 확인할 수 있다.
4. Authentication → Sign-in method → Google을 활성화하고 지원 이메일을 설정한다.
5. 변경 후 새 `google-services.json`을 내려받아 **android/app/google-services.json**에 넣는다.
   `oauth_client` 안에 `client_type: 3`인 웹 OAuth 클라이언트가 있어야 한다.
6. 프로젝트 루트에서 `flutter pub get`을 실행하고 사용자가 APK를 빌드한다.
   Gradle은 설정 파일이 있을 때 Google Services 플러그인을 적용한다.
   Dart는 생성된 firebase_options.dart의 DefaultFirebaseOptions.currentPlatform으로 초기화한다.
   google-services.json은 Android Google 로그인에 필요한 OAuth 리소스 생성에도 사용된다.

설정 파일에 서비스 계정 비밀키를 넣지 않는다. Admin SDK 서비스 계정 키는 앱에 포함하지 않는다.
구글 계정 선택 뒤 취소로 돌아오는 경우에도 패키지 이름·서명 지문·웹 OAuth 클라이언트를 확인한다.

## 확장 구조

- `AuthRepository`: 앱의 인증 계약. Firebase UID를 영속적인 사용자 키로 사용한다.
- `FirebaseAuthRepository`: Firebase 세션과 공급자 전략 맵을 관리한다.
- `FirebaseLoginStrategy`: 공급자별 로그인 절차. 현재는 Google만 등록한다.
- `AccountViewModel`: 준비·진행·실패·취소·로그아웃과 중복 요청 방지.
- `AccountPage`: 첫 실행 로그인 화면 및 홈 상단 내 계정 아이콘에서 접근한다.
  supportedProviders에 등록된 공급자별로 버튼을 표시한다. 현재 Google만 제공하며 네이버·카카오는 추가 예정 안내만 표시한다.

카카오·네이버는 새 전략을 추가한다. 외부 access token을 서버에서 공급자 API로 검증한 뒤
Admin SDK로 Firebase custom token을 발급하고 앱에서 signInWithCustomToken으로 로그인한다.
앱에서 전달한 사용자 ID나 이메일만으로 토큰을 발급하거나 계정을 자동 합치면 안 된다.
기존 계정에 추가 공급자를 연결하려면 로그인한 Firebase ID token과 새 공급자 자격을
모두 서버에서 검증하고 같은 UID로 연결하는 별도 절차가 필요하다.
현재 코드에는 미구현 공급자를 실제 로그인 버튼으로 노출하지 않는다.

## 이번 검증 범위

자동 테스트는 `test/account_test.dart`의 핵심 5개만 실행한다.
가짜 인증 저장소로 복원·로그아웃, 중복 요청·취소·재시도, 설정 실패·공급자 확장,
dispose 이후 안전성, 작은 화면 로그인 UI를 확인한다.
실제 Google/Firebase SDK 로그인과 Android 네이티브 빌드는 설정 파일 및 의존성 설치 후 확인해야 한다.
패키지는 설치되어 있으며 Dart 진입점 컴파일과 인증 테스트 5개를 통과했다.
실제 로그인 검증은 Firebase 설정 및 사용자 측 Android 빌드 후에 필요하다.

Google 아이콘: `images/google_sign_in.png`는 Google 공식 브랜드 자료 원본이다.
https://developers.google.com/static/identity/images/g-logo.png
브랜드 안내: https://developers.google.com/identity/branding-guidelines

## 공식 자료

- https://firebase.google.com/docs/auth/flutter/federated-auth
- https://firebase.google.com/docs/flutter/setup
- https://pub.dev/packages/google_sign_in_android
- https://firebase.google.com/docs/auth/flutter/custom-auth

## 영작 AI 평가 (Firebase AI Logic · Gemini)

영작 대답은 `GeminiWritingEvaluator`가 Firebase AI Logic의 Gemini Developer API로 평가한다.
모델은 `gemini-3.5-flash-lite`(무료 등급 제공 모델, 2026-10-08 확인). Flash보다 무료 일일 요청 수가 넉넉한 경량 모델이다. Spark 요금제에서 무료 등급으로 사용한다.
무료 등급 입력은 Google 제품 개선에 사용될 수 있다. 영작 대답은 짧은 상황 연습 문장이며, 화면 안내 문구는 두지 않는다(사용자 결정).
정식 배포 시 개인정보 처리방침에 Gemini 전송 사실을 적는다.
호출 실패(오프라인·한도 초과·App Check 미설정 등) 시 `OfflineWritingEvaluator` 간이 평가로 대체하고,
실패 원인은 logcat에 `GeminiWritingEvaluator failed:`로 출력한다.

2026-10-08 사용자 완료 보고: AI Logic·App Check 설정, 디버그 토큰 등록(이름 `insucom`). 실제 호출은 미검증.

콘솔 설정 (사용자 수행):

1. Firebase 콘솔 → AI Services → AI Logic → 시작하기 → **Gemini Developer API** 선택.
2. 2026년 7월 이후 AI Logic은 App Check가 자동 적용된다. Security → App Check에서 Android 앱에
   **Play Integrity** 공급자를 등록한다(SHA-256 지문 필요).
3. 디버그 빌드는 고정 디버그 토큰을 사용한다. App Check → 앱 메뉴 → **디버그 토큰 관리**에
   `756BFABF-BD4F-4621-8C58-B3E3A63571C2`를 추가한다. 이 토큰은 디버그 빌드에만 포함되며, 유출 시 콘솔에서 삭제한다.
4. Security → App Check → APIs에서 AI Logic이 enforced인지 확인한다.

릴리스 빌드는 Play Integrity를 사용한다. Play 스토어 외 경로로 설치한 릴리스 APK는 검증에 실패할 수 있으며,
이 경우 간이 평가로 대체된다. 모델 이름은 Remote Config로 옮기면 앱 업데이트 없이 바꿀 수 있다.

- https://firebase.google.com/docs/ai-logic/get-started?platform=flutter
- https://firebase.google.com/docs/ai-logic/pricing
- https://ai.google.dev/gemini-api/docs/pricing
