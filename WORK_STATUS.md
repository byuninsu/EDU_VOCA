# Daily English — 현재 작업 상태

갱신: 2026-10-19. 이 문서는 현재 상태만 유지하며, 과거 작업 로그를 누적하지 않습니다.
제품·실행 안내는 [README.md](README.md), 학습 규칙은 [CONCEPT.md](CONCEPT.md)를 참고합니다.

## 현재 구현

- 기능별 MVVM + Service + Repository. 강아지 테마, 짧은 홈, 학습 바로가기 및 완료 팝업.
- 2,897개 단어·숙어 대화 빈칸 학습. 상황 제목, 앞 대사와 빈칸 대사, 각 한국어 해석 표시.
  등장인물은 남녀 각 20개 이름에서 무작위 선택, 순서도 무작위. 다음 문제에서는 두 이름 모두 교체, 현재 문제와 해설에서는 유지.
  `dialogue_contexts.dart`: 숙어 64개와 기존 앱 예문에 개별 앞 대사, 나머지는 주제별·일반 대화 도입문. 전체 대화 개별 검수는 아님.
  정답·예문·복습 ID는 유지. 빈칸 직접 입력, 숙어 단어별 밑줄, 재시도·힌트·복습·레벨 조정.
  세션 생성 때 미학습 단어 선택과 새 문제 순서 무작위화. 현재 난이도 비율과 오답 우선순위 유지.
- 경험치 레벨: `LearningProgress.xp`·`xpWords`, 필요량 `xpNeeded`(Lv.1 5 → Lv.19 20), 정답 +1·오답 −2(`LearningService._experience`).
  이전 기록의 `levelStreak`은 경험치로 이어받음. 화면: `XpBar`(홈 상단·정답 팝업·완료 팝업), 레벨 업 팝업(`showLevelUp`).
- 복습: `ReviewEntry`에 틀린 횟수(`misses`)·마지막 오답 시각(`lastMissed`) 저장(이전 기록은 1회·시각 없음으로 읽음).
  세션에 기한 된 복습 최대 40%, 많이 틀린 순 → 오래 밀린 순. `LearningService.spread`로 새 문제 사이에 고르게 배치.
  정답 간격 `LearningService.interval`(1/3/7/14/30일 ÷ (1 + 0.5×(틀린 횟수−1)), 최소 1일). 문제 태그 `Exercise.label`.
- 출제 비율(10문제 기준): 숙어 2개, 문법 단어(전치사·관사·대명사·접속사 등) 1개 이하, 명사 3개 이하, 나머지 동사·형용사·부사 우선.
  품사는 `WordItem.isFunctionWord`/`isNounLike`가 표제어 대표 품사로 판정. 문맥별 품사가 아님.
- 입력: 앱 전용 간이 영어 키패드(`CompactKeyboard`, 4줄). 빈칸은 `TextInputType.none`이라 시스템 키보드가 뜨지 않음.
  영어 대사는 한 줄을 목표로 글자 크기 조정(18~14), 해석은 14~12. 빈칸 실제 폭도 반영하며 최소 크기에서 긴 문장은 줄바꿈. 대화 카드 여백 축소.
- 단어 연습 화면: 상단 바 제거, 맨 윗줄에 작은 `BackButton`, 그 아래 '새로운 표현 · n/10'. 여백·키 높이(36) 축소.
  키패드는 화면 하단 고정, 대화 영역만 스크롤. 390×844와 320×640·글자 배율 1.6 검증.
- 단어 연습 화면: 안내 문구·정답 확인 버튼·출처 제거. 정답 글자 수에 도달하거나, 글자 수가 달라도 준비된 같은 뜻 단어·틀린 형태와 일치하면 즉시 자동 채점(오답이면 문구만 표시하고 재입력).
  숙어는 단어 칸이 차면 다음 칸으로 자동 이동.
- 오답 안내: 문장 아래 안내 문구(색상·전환 효과), 즉시·오프라인 판정(`LocalClozeCheck`). 연습 중 LLM 호출 없음.
  판정 자료(`lib/data/local/cloze_cues.dart`): 같은 뜻 단어는 Claude가 문장별 작성(2,903개 중 1,482개에 항목),
  틀린 형태는 활용 규칙으로 생성(2,394개). `tools/build_cloze_cues.py`로 재생성, 예문 변경 시 해당 목록 제외·보고.
  형용사↔부사 혼동(`special`→`specially` 자리 등)은 `LocalClozeCheck.slip`이 -ly 규칙으로 찾아 품사와 맞는 형태를 안내.
  다른 단어의 앞부분일 수 있는 입력(`special`/`specially`)은 1.2초 멈춘 뒤 판정.
  힌트는 빈칸에 첫 글자 채우기. Firebase AI 설정은 `FirebaseAiSetup`(영작 평가 전용, `gemini-3.5-flash-lite`).
- 정답 확인·공개 모두 해설 팝업. 두 대사와 해석을 표시하고 전체 대화를 한 번 자동 재생. 대화 듣기·천천히 듣기 버튼 제공(정지 버튼 없음, 닫으면 중지).
  확인 시 다음 단어, 마지막 문제는 완료 팝업으로 진행.
- 하단 메뉴바 없음. 홈의 단어·영작·복습 바로가기로 들어가고, 상단 뒤로가기·기기 뒤로가기로 홈 복귀.
- 출처: 설정 페이지 하단 '자료 출처'에만 3줄 텍스트로 표시(홈·단어장에서 제거, 팝업 없음). 상세 출처·변경 내역·라이선스 링크는 `data/*/NOTICE.md`.
- 안내·오류 문구는 문장마다 `
`으로 직접 줄바꿈(자동 줄바꿈에 맡기지 않음). 새 문구도 같은 규칙.
- 대표 품사 표시, 한국어 해석 대응 구간 강조. 전체 항목에 품사·강조 구간이 존재하지만 언어 전문가 검수를 뜻하지는 않음.
- `data/examples/reviewed.json`의 17개 예문을 자동 선택보다 우선 적용. rose/found 동형어 오연결과 capital 번역 등을 교체.
- 문장 음성: 기기 내장 KittenTTS nano v0.8 int8(sherpa-onnx 1.13.8), 목소리 0번. 백그라운드 isolate에서 합성하고 MainActivity의 AudioTrack으로 재생.
  문제 표시 시 현재 문장을 미리 합성(최근 12개 메모리 캐시), 느린 재생은 속도 0.7로 별도 합성. 엔진 실패 시 그 세션은 `flutter_tts`로 대체.
  첫 사용 시 모델(약 28MB)을 앱 내부 저장소로 한 번 복사. 음성 중지 응답이 늦어도 화면 이동은 진행.
- Firebase Google 로그인·로그아웃·세션 복원. 학습 기록은 SharedPreferences의 `daily_english_v1`에 기기 단위로 저장.
- 영작 대화: 상대 대사 TTS → 영어 대답 → Gemini(`gemini-3.5-flash-lite`, Firebase AI Logic 무료 등급) 평가.
  Very good(내 문장 읽기·복습 제외) / Good(Very good 표현·다른 예시 표시·읽기·복습 저장) / 다시 해봐요(힌트, 무제한 재도전, 예시 답안 보기).
  AI 실패 시 `OfflineWritingEvaluator` 간이 평가로 대체하고 화면에 표시. 상황 6개 × 5턴(`lib/data/local/scenarios.dart`, `DialogueTurn`).
  복습 저장 형식 `턴번호	답변`(이전 형식은 첫 턴으로 읽음), 복습에서 해당 턴부터 시작.
  결과는 팝업(다시 써 볼게요·예시 답안 보기 / 연습 마치기·다른 표현으로 다시 써보기), 닫은 뒤 다시 보기 가능.

## 연결·의존성 상태

- Firebase 프로젝트 `edu-voca`, Android 패키지 `com.dailyenglish.edu_voca`.
- `google-services.json` 및 `firebase_options.dart` 연결됨. 설정 간 일치, OAuth 클라이언트와 디버그 SHA-1 일치는 확인함.
- SHA-256 등록과 Google 공급자 활성화는 사용자 완료 보고. 실제 기기 로그인 성공은 직접 검증하지 않음.
- `flutter_tts` 4.2.5는 `third_party/flutter_tts`의 로컬 패키지 사용. Android Gradle을 AGP 내장 Kotlin에 맞게 수정함.
- `sherpa_onnx` 1.13.8: arm64/x86_64 네이티브 라이브러리 16KB 정렬 확인. 32비트 x86 라이브러리는 패키징에서 제외.
  모델 자산 `assets/tts/kitten_nano_v0_8/`, espeak-ng 영어 자료만 유지. 출처·라이선스는 `data/tts/NOTICE.md`. 별도 TTS 서버 없음.

## 최신 검증

출처 팝업 제거 후 `widget_test.dart` 16개 중 13개 통과(신규 'Home shows sources as plain text without a popup' 포함). 남은 3개는 기존 미갱신 테스트.

영작 5턴 대화 변경 후 통과 (근거 `build/writing-turns-tests.log`): `writing_coach_test.dart` 8개
(5턴 순서 진행·깨끗한 완주 시 복습 제외·복습 턴부터 시작, 6개 상황×5턴 자료 완결성, 팝업 '다음 대화로'·'이전 대화 보기' 시트·턴별 복습 저장,
마지막 턴 연습 마치기). 영작 ViewModel 저장 왕복, 예시 답안 보기, 이전 복습 형식 호환 테스트 통과.

영작 결과 팝업 변경 후 통과 (근거 `build/writing-popup-tests.log`): `writing_coach_test.dart` 5개(팝업 내 Very good·Good 표시,
읽어주기, 연습 마치기로 화면 종료, 다시 써보기 후 팝업 닫힘), 영작 예시 답안 보기·복습 저장, 영작 ViewModel 저장 왕복.

상단 바 제거·키패드 변경 후 통과 (근거 `build/no-appbar-tests.log`):
`answer_dialog_test.dart` 5개, `cloze_guide_test.dart` 6개(키패드 입력·칸 이동·지우기, 최장 15개 예문 2줄·스크롤 없음).
임시 전수 측정(Arial로 Roboto 근사): 2,903문제 모두 2줄 이내, 키패드 표시 상태에서 390×844·360×780·360×740·360×640 모두 스크롤 없음.
`widget_test.dart` 15개 중 12개 통과: 키패드·숙어 우선 출제·출처 제거에 맞춰 테스트 4개 갱신.
남은 실패 3개는 이전 팝업 흐름 변경 때부터 갱신되지 않은 테스트(미수정): 'Each question shows separate frequency…'('다음 문제' 버튼 기대),
'Live blank updates…'(`ClozeSentence.input` 속성 기대), 'Sentence cloze retries…'.
이전 검증: 영작 AI 평가 5개(`build/writing-coach-tests.log`), 출제 비율 5개(`build/session-mix-tests.log`),
Kitten 음성 3개(`build/kitten-tts-tests.log`). Gemini 실제 호출과 APK 빌드·실기기 검증은 하지 않음.
기존 실패(이전 원본 코드로도 실패, 미수정): `sentence_speech_test.dart` 팝업 재생 4개.

## 남은 작업

- 사용자 빌드 후 실제 기기에서 로그인, 빈칸 입력·키보드, 팝업 전환·문장 재생 확인.
- Kitten 음성은 실기기 미검증: 첫 실행 모델 복사 시간, 합성 지연, 팝업 자동 재생, 음질·목소리(0~7번) 확인 필요.
- APK 크기 증가 확인(예상: 모델 약 28MB + ABI별 네이티브 약 20~27MB). 배포 시 AAB 또는 `--split-per-abi` 권장.
- espeak-ng(GPL-3.0) 포함에 따른 배포 조건 검토.
- 예문·번역·문맥별 품사 검수. 현재 품사는 표제어의 대표 품사이며 번역 강조는 규칙·대응 구간 기반.
- AI 영작 평가 실기기 미검증. AI Logic·App Check·디버그 토큰(`insucom`) 등록은 사용자 완료 보고.
  디버그 빌드로 평가 품질·응답 시간·무료 한도 확인 필요.
- `firebase_ai` 4.0.0, `firebase_app_check` 0.4.8 추가. 두 플러그인 모두 AGP 9 내장 Kotlin 분기 확인, 빌드는 미검증.
- 카카오·네이버, 계정별 기록 분리·동기화, AI 영작 자유 대화(상대 대사 생성) 등은 미구현.
- 배포 전 Oxford 자료 이용허락, 배포 서명, 최신 APK의 16KB 환경 호환성 확인 필요.

## 작업 원칙

- APK 빌드는 사용자가 수행. 변경 검증은 관련 핵심 테스트 5개로 제한.
- 문서는 해당 항목을 갱신하고, 폐기된 설명·중복 이력은 제거. 별도 이력 문서를 자동 생성하지 않음.
- 자료 재생성: `tools/build_ngsl.py`, `tools/build_examples.py`, `tools/build_word_hints.py`, `tools/build_cloze_cues.py`. 원본 출처·이용조건 문서는 유지.
