# Daily English

Flutter 기반 Android 영어 학습 앱. 강아지 캐릭터와 함께 예문 속 단어·숙어, 상황별 영작, 오답 복습을 연습합니다.

## 주요 기능

- NGSL·NGSL-Spoken 단어 2,833개 + 앱 작성 숙어·구동사 64개, 총 2,897개.
- 예문 빈칸에 직접 입력. 숙어는 단어별 가변 길이 밑줄로 표시합니다.
- 한국어 전체 해석의 대응 표현 강조, 대표 품사·빈도·난이도 힌트 제공.
- 정답 확인·공개 시 해설 팝업 표시. 확인을 누르면 다음 문제로 이동합니다.
- 문장 자동 읽기 및 일반·느린 재생. 기기 내장 KittenTTS nano 음성을 쓰고, 실패하면 휴대폰 기본 TTS(`flutter_tts`)로 읽습니다.
- 하루 목표 이후에도 계속 학습. 영작은 상대 대사를 듣고 대답하면 Gemini(Firebase AI Logic)가 Very good·Good·재도전으로 평가합니다.
- Firebase Google 로그인 및 세션 복원. 학습 기록은 기기에 저장하며 계정 동기화는 없습니다.

세부 학습 규칙은 [CONCEPT.md](CONCEPT.md), 검증 상태와 남은 작업은 [WORK_STATUS.md](WORK_STATUS.md)를 참고하세요.

## 실행과 빌드

Android Studio에서 프로젝트 루트 폴더를 엽니다. 현재 개발 SDK는 Flutter 3.47.6 / Dart 3.13.5이며, 로컬 Flutter 경로는 `C:\flutter\flutter`입니다.
Android 7.0(API 24) 이상을 대상으로 하며 iOS는 미구현입니다.

```powershell
flutter pub get
flutter devices
flutter run -d <device-id>
```

Firebase 설정 파일은 현재 프로젝트에 연결되어 있습니다. 새 환경에서는 [Firebase 설정 안내](docs/FIREBASE_SETUP.md)를 확인하세요.

APK 빌드는 사용자가 수행합니다.

```powershell
flutter build apk --debug
```

출력: `build/app/outputs/flutter-apk/app-debug.apk`. 배포용 서명은 아직 설정하지 않았습니다.
Android 구성은 Gradle 9.3.1 / AGP 9.1.0 / 내장 Kotlin, compileSdk 36 / targetSdk 35 / Build-Tools 36.0.0입니다.

## 개발 구조

기능별 **MVVM + Service + Repository** 구조입니다. [상세 아키텍처](docs/ARCHITECTURE.md).

- `lib/app/`: 앱 구성·의존성 주입·테마.
- `lib/features/`: 기능별 View·ViewModel.
- `lib/domain/`: 모델·학습 규칙·저장소 인터페이스.
- `lib/data/`: 로컬 자료·저장소·인증 및 음성 서비스.
- `lib/shared/widgets/`: 공통 UI.
- `tools/`, `test/`: 데이터 생성과 검증.

변경에 관련된 핵심 테스트 5개를 선택해 확인합니다. 현재 정답 팝업·힌트 검증은 `test/answer_dialog_test.dart`입니다.
`flutter_tts`는 내장 Kotlin 대응을 위해 로컬 패키지를 사용합니다. [수정 내역](third_party/flutter_tts/LOCAL_CHANGES.md).

## 자료와 이용조건

- [NGSL·NGSL-Spoken](data/ngsl/NOTICE.md): 단어·빈도 자료, CC BY-SA 4.0.
- [Oxford 3000/5000](data/oxford/NOTICE.md): CEFR·대표 품사. 별도 이용조건 적용, 배포 허락은 미확보.
- [예문 자료](data/examples/NOTICE.md): Tatoeba 문장쌍 및 앱 작성 예문·해석. 전문가 검수 전입니다.
- [문장 음성](data/tts/NOTICE.md): KittenTTS nano·sherpa-onnx(Apache 2.0), espeak-ng 영어 자료(GPL-3.0).

앱 메인·설정·단어장 하단에 출처와 라이선스를 짧은 글씨로 표시합니다(팝업 없음). 상세 출처와 편집 내역은 각 NOTICE 문서에 있습니다.
