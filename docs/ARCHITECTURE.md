# 기능별 MVVM + Service + Repository

기존 화면 동작과 `daily_english_v1` 저장 형식을 유지했다.
상태 알림은 ChangeNotifier를 사용하며 새 패키지는 추가하지 않았다.

```text
lib/
  main.dart                 # 저장소 준비와 의존성 주입
  app/                      # MaterialApp, 테마
  domain/
    models/                 # 단어, 학습 기록, 문제, 복습, 영작 상황
    services/               # 출제, 레벨, 복습, 날짜 전환
    repositories/           # 조회·저장 인터페이스
  data/
    local/                  # NGSL/Oxford, 기존 예문, 영작 상황
    repositories/           # 로컬 조회, SharedPreferences, 메모리 저장
  features/
    home/views/             # 홈과 탭 탐색
    learning/               # views/ + view_models/
    writing/                # views/ + view_models/
    vocabulary/             # views/ + view_models/
    settings/               # views/ + view_models/
  shared/widgets/           # 공통 UI, 출처, 빈도·난이도
```

## 책임과 의존성

- View: 화면 표시, 입력 컨트롤러, 포커스, 키보드, 화면 이동.
- 기능 ViewModel: 재도전·정답 공개·세션 진행, 영작 비교, 검색 필터, 설정 초안. Widget이나 BuildContext에 의존하지 않는다.
- LearningViewModel: 공통 학습 상태 노출, Service 호출, 변경 알림, 저장 큐와 오류 안내. 계산 규칙이나 SharedPreferences API를 포함하지 않는다.
- LearningService: 순수 Dart 학습 규칙. Flutter나 저장소 구현체를 import하지 않는다.
- VocabularyRepository: 단어·기존 복습 ID·영작 상황 조회 계약. 로컬 구현이 NGSL과 Oxford를 결합하므로 Model은 원본 데이터에 의존하지 않는다.
- ProgressRepository: 로컬 스냅샷 읽기와 비동기 저장 계약. SharedPreferences 및 메모리 구현 제공. 서버 동기화 추가 시 캐시 초기화와 비동기 동기화 정책은 별도로 정의한다.

구현체는 main.dart에서 주입한다. ViewModel에서 저장소를 직접 생성하거나 전역 데이터를 읽지 않는다.
새 기능은 features 아래에 만들고, 공유 학습 규칙만 domain으로 옮긴다.
현재 규모에서는 하나의 LearningService로 충분하며 기능이 커질 때 출제·복습 등을 각각 추출한다.

## 상태와 수명

화면별 ViewModel을 한 번 생성하고 변경 알림을 구독한다. 화면 종료 시 구독,
ViewModel, 입력 컨트롤러를 해제한다. 공통 LearningViewModel은 앱 수명 동안 공유한다.
컬렉션은 읽기 전용으로 노출하고 변경은 메서드를 거친다.
저장은 호출 시점의 스냅샷을 순서대로 처리하며 flush()로 완료를 기다릴 수 있다.
dispose 이후의 저장 실패는 폐기된 notifier에 알리지 않는다.

## 호환성과 검증

저장 키, JSON 필드, 구형 레벨 이관, 복습 ID, 단어 수와 분류 기준은 유지했다.
데이터 생성 스크립트는 이제 lib/data/local/에 출력한다.

예문 빈칸 학습은 ClozeExample 모델과 data/local/cloze_examples.dart로 추가했다.
LocalVocabularyRepository가 모든 단어에 예문·전체 해석·문장 내 정답 형태·출처를 연결한다.
기존 문장 예문을 우선 유지하며 단어장 기본형과 뜻은 meaning/lemma에 보존한다.
tools/build_examples.py로 예문을 재생성한다. View에는 예문 생성·활용형 변환 로직이 없다.
숙어·구동사 64개는 data/local/phrases.dart에서 같은 WordItem으로 제공한다.
LearningService가 정규 학습에 섞고 VocabularyViewModel이 전용 필터를 관리한다.
공식 빈도·CEFR가 없는 표현에는 해당 메타데이터를 부여하지 않으며 레벨 증감에서 제외한다.
공통 ClozeSentence 위젯이 정답과 입력의 실제 글꼴 너비에 맞춰 연속 밑줄을 그린다.
이 변경 이후 데이터 및 UI 테스트는 총 36개 통과했다.

2026-10-08: Dart 분석 서버에서 lib/test 오류·경고 없음. 기존 회귀 및 신규
ViewModel/Repository 테스트 30개 통과. 좁은 화면·큰 글자와 화면 미리보기도 확인했다.
일반 Flutter 래퍼의 SDK 잠금 쓰기 권한 문제 때문에 설치된 frontend server와
Flutter 테스트 엔진으로 동일 테스트를 실행했다. 테스트 산출물은 build/에 생성했다.
APK는 빌드하지 않았다. 일반 개발 환경에서는 flutter analyze와 flutter test를 사용한다.

## 문장 음성

SentenceSpeechService가 재생 순서·취소를 관리하고 KittenSpeechEngine(data/services)이 합성을 맡는다.
엔진은 sherpa-onnx를 백그라운드 isolate에서 실행하고, PCM은 MainActivity의 `edu_voca/speech_audio`
채널(AudioTrack)로 재생한다. 오디오 플러그인을 추가하지 않은 이유는 AGP 9 내장 Kotlin 호환성 때문이다.
Android가 아니거나 엔진이 실패하면 flutter_tts로 대체한다. 테스트는 엔진을 주입해 검증한다.
