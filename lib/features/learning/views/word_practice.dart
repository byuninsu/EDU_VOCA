import 'dart:async';
import '../view_models/word_practice_view_model.dart';
import '../view_models/sentence_speech_view_model.dart';
import 'package:flutter/material.dart';
import 'package:edu_voca/domain/models/exercise.dart';
import 'package:edu_voca/features/learning/view_models/learning_view_model.dart';
import 'package:edu_voca/shared/widgets/ui.dart';
import 'package:edu_voca/shared/widgets/word_indicators.dart';
import 'package:edu_voca/shared/widgets/cloze_sentence.dart';
import 'package:edu_voca/shared/widgets/compact_keyboard.dart';
import 'package:edu_voca/shared/widgets/xp_bar.dart';
import 'package:edu_voca/domain/models/learning_progress.dart';
import 'package:edu_voca/domain/services/word_cues.dart';
import 'package:edu_voca/shared/widgets/dialogue_turn.dart';

class WordPractice extends StatefulWidget {
  final LearningViewModel state;
  final List<Exercise> exercises;
  final bool countsToday;
  const WordPractice(
      {super.key,
      required this.state,
      required this.exercises,
      required this.countsToday});
  @override
  State<WordPractice> createState() => _WordPracticeState();
}

class _WordPracticeState extends State<WordPractice>
    with WidgetsBindingObserver {
  final speech = SentenceSpeechViewModel();
  final input = TextEditingController();
  final keys = ClozeKeys();
  bool _revealed = false;
  bool _answerDialogOpen = false;
  Timer? _pause;
  Exercise? _celebrated;
  late final WordPracticeViewModel vm = WordPracticeViewModel(
      learning: widget.state,
      exercises: widget.exercises,
      countsToday: widget.countsToday);
  Exercise? _hintFilled;
  int get index => vm.index;
  int get hits => vm.hits;
  bool? get correct => vm.correct;
  bool get finished => vm.finished;
  List<Exercise> get exercises => vm.exercises;
  bool get countsToday => vm.countsToday;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    vm.addListener(_refresh);
    _prepareSpeech();
  }

  void _refresh() {
    _fillHint();
    if (mounted) setState(() {});
    _prepareSpeech();
  }

  /// A shown hint puts the first letter at the start of the blank.
  void _fillHint() {
    if (!vm.hintVisible || correct != null || finished) return;
    final exercise = exercises[index];
    if (identical(_hintFilled, exercise)) return;
    _hintFilled = exercise;
    final letter = vm.firstLetter;
    if (!input.text.toLowerCase().startsWith(letter.toLowerCase())) {
      input.text = letter;
    }
  }

  /// Synthesizes the current sentence while the learner is still answering.
  void _prepareSpeech() {
    if (!finished && index < exercises.length) {
      speech.prepare(vm.completeDialogue);
    }
  }

  @override
  void dispose() {
    _pause?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    speech.dispose();
    vm.removeListener(_refresh);
    vm.dispose();
    input.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) speech.stop();
  }

  /// Checks automatically once the typed letters match the answer's length,
  /// or once they spell a prepared same-meaning word, wrong form or
  /// adjective/adverb mix-up.
  void _onInput() {
    if (correct != null || finished) return;
    final typed = input.text.replaceAll(RegExp(r'\s'), '');
    final target = exercises[index].word.answer.replaceAll(RegExp(r'\s'), '');
    _pause?.cancel();
    if (typed.length == target.length) return submit();
    switch (vm.earlyCheck(input.text)) {
      case EarlyCheck.now:
        submit();
      case EarlyCheck.afterPause:
        final text = input.text;
        _pause = Timer(const Duration(milliseconds: 1200), () {
          if (mounted && input.text == text) submit();
        });
      case EarlyCheck.none:
    }
  }

  void submit() {
    if (correct != null || finished) return;
    vm.submit(input.text);
    if (vm.correct != null) {
      FocusScope.of(context).unfocus();
      _revealed = true;
      showAnswer();
    }
  }

  void grade(bool result) {
    FocusScope.of(context).unfocus();
    if (!result && correct == null) {
      _revealed = true;
      vm.reveal();
      showAnswer();
    }
  }

  void continuePractice() {
    _revealed = false;
    input.clear();
    vm.continuePractice();
  }

  Future<void> next() async {
    unawaited(speech.stop());
    if (!mounted) return;
    _revealed = false;
    input.clear();
    vm.next();
    if (!vm.finished) return;
    final keepLearning = await showDialog<bool>(
        context: context,
        builder: (context) => Dialog(
            backgroundColor: paper,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const PuppyMascot(size: 140, pose: PuppyPose.happy),
                      const SizedBox(height: 12),
                      const TitleText('한 걸음 더 성장했어요!', size: 22),
                      const SizedBox(height: 12),
                      Text('${exercises.length}문제 완료 · $hits문제 정답',
                          textAlign: TextAlign.center),
                      const SizedBox(height: 14),
                      xpBar(),
                      const SizedBox(height: 20),
                      ActionButton('단어 계속하기',
                          onPressed: () => Navigator.pop(context, true)),
                      const SizedBox(height: 8),
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('학습 홈으로')),
                    ])))));
    if (!mounted) return;
    if (keepLearning == true) {
      continuePractice();
    } else if (keepLearning == false) {
      Navigator.pop(context);
    }
  }

  Future<void> showAnswer() async {
    if (_answerDialogOpen || !mounted) return;
    _answerDialogOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _answerDialogOpen) speech.speak(vm.completeDialogue);
    });
    bool? advance;
    try {
      advance = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => Dialog(
              backgroundColor: paper,
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28)),
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                                tooltip: '닫기',
                                onPressed: () => Navigator.pop(dialogContext),
                                icon: const Icon(Icons.close_rounded))),
                        Flexible(
                            child: SingleChildScrollView(child: feedback())),
                        const SizedBox(height: 16),
                        ActionButton('확인',
                            onPressed: () =>
                                Navigator.pop(dialogContext, true)),
                      ])))));
    } finally {
      _answerDialogOpen = false;
      unawaited(speech.stop());
    }
    final exercise = exercises[index];
    if (mounted &&
        vm.xpResult.levelChange > 0 &&
        !identical(_celebrated, exercise)) {
      _celebrated = exercise;
      await showLevelUp();
    }
    if (mounted && advance == true) await next();
  }

  Widget xpBar() => XpBar(
      level: widget.state.level,
      xp: widget.state.xp,
      needed: widget.state.xpToNext,
      wide: true);

  /// Celebrates a level up and says honestly what changes next.
  Future<void> showLevelUp() {
    final level = widget.state.level;
    final String message;
    if (LearningProgress.starsOf(level) !=
        LearningProgress.starsOf(level - 1)) {
      message = '이제 ${LearningProgress.cefrOf(level)} 단어를 중심으로 학습해요.\n'
          '앞으로 더 어려운 단어에 도전해 봐요!';
    } else if (level >= LearningProgress.maxLevel) {
      message = '최고 레벨에 도착했어요!\n지금처럼 꾸준히 복습해 봐요.';
    } else {
      final band = LearningProgress.starsOf(level) * 4 + 1;
      message = '다음 레벨까지 경험치 ${widget.state.xpToNext}이 필요해요.\n'
          '${band - level}레벨 더 오르면 ${LearningProgress.cefrOf(band)} 단어를 만나요.';
    }
    return showDialog<void>(
        context: context,
        builder: (context) => Dialog(
            key: const ValueKey('level-up'),
            backgroundColor: paper,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const PuppyMascot(size: 120, pose: PuppyPose.happy),
                      const SizedBox(height: 12),
                      const TitleText('레벨이 올랐어요! 🎉', size: 22),
                      const SizedBox(height: 6),
                      Text('Lv. ${level - 1} → Lv. $level',
                          style: const TextStyle(
                              color: teal,
                              fontSize: 18,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      Text(message, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      xpBar(),
                      const SizedBox(height: 20),
                      ActionButton('계속하기',
                          onPressed: () => Navigator.pop(context)),
                    ])))));
  }

  /// One line on how this answer moved the experience bar.
  Widget xpChange(Exercise exercise) {
    final result = vm.xpResult;
    final state = widget.state;
    final String text;
    if (result.levelChange > 0) {
      text = '경험치 +${result.gained} · 레벨 업!';
    } else if (result.levelChange < 0) {
      text = '경험치 ${result.gained} · Lv. ${state.level}로 내려갔어요.\n'
          '다시 차근차근 올려 봐요.';
    } else if (result.gained != 0) {
      text = '경험치 ${result.gained > 0 ? '+' : ''}${result.gained}';
    } else if (exercise.word.difficultyStars != state.targetStars) {
      text = '현재 난이도(${state.targetCefr}) 단어가 아니라\n경험치는 그대로예요.';
    } else {
      text = state.xpToNext == 0 ? '최고 레벨이에요.' : '이 레벨에서 이미 경험치를 받은 단어예요.';
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(text,
          key: const ValueKey('xp-change'),
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: result.gained < 0 ? const Color(0xFFC2523C) : teal)),
      const SizedBox(height: 6),
      xpBar(),
    ]);
  }

  static const _toneColors = {
    GuideTone.idle: muted,
    GuideTone.hint: Color(0xFFB0721E),
    GuideTone.close: teal,
    GuideTone.wrong: Color(0xFFC2523C),
  };

  /// Guidance that changes with each attempt; colour and a short slide make
  /// a new message noticeable.
  Widget _guide() => Semantics(
      liveRegion: true,
      child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                  position: Tween(begin: const Offset(0, .35), end: Offset.zero)
                      .animate(animation),
                  child: child)),
          child: Text(vm.guide,
              key: ValueKey('${vm.tone}|${vm.guide}'),
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: vm.tone == GuideTone.idle
                      ? FontWeight.w400
                      : FontWeight.w700,
                  color: _toneColors[vm.tone]))));

  Widget feedback() {
    final word = exercises[index].word;
    final parts = word.sentence.split('____');
    return Panel(
        color: correct! ? mint : const Color(0xFFFFEEDB),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            PuppyMascot(
                size: 56,
                pose: correct!
                    ? PuppyPose.happy
                    : vm.solvedWithHint
                        ? PuppyPose.studying
                        : PuppyPose.disappointed),
            const SizedBox(width: 10),
            Expanded(
                child: TitleText(
                    correct!
                        ? '잘했어요!\n정확한 표현이에요.'
                        : vm.solvedWithHint
                            ? '표현을 완성했어요!\n힌트 사용으로 복습에 저장해요.'
                            : '괜찮아요.\n이번에 기억해 봐요.',
                    size: 17)),
          ]),
          const SizedBox(height: 12),
          _partnerTurn(),
          const SizedBox(height: 10),
          DialogueTurn(
              speaker: vm.cast.learner,
              reply: true,
              english: Text.rich(
                  key: const ValueKey('answer-sentence'),
                  TextSpan(children: [
                    for (var i = 0; i < parts.length; i++) ...[
                      TextSpan(text: parts[i]),
                      if (i < parts.length - 1)
                        TextSpan(
                            text: word.answer,
                            style: const TextStyle(
                                color: teal,
                                backgroundColor: mint,
                                fontWeight: FontWeight.w800)),
                    ],
                  ]),
                  style:
                      const TextStyle(fontSize: 20, height: 1.5, color: ink)),
              translation: Text(word.translation,
                  style:
                      const TextStyle(fontSize: 15, height: 1.4, color: ink))),
          const SizedBox(height: 8),
          AnimatedBuilder(
              animation: speech,
              builder: (context, _) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(spacing: 4, children: [
                          TextButton.icon(
                              onPressed: () =>
                                  speech.speak(vm.completeDialogue),
                              icon:
                                  const Icon(Icons.volume_up_rounded, size: 20),
                              label: const Text('대화 듣기')),
                          TextButton.icon(
                              onPressed: () =>
                                  speech.speak(vm.completeDialogue, slow: true),
                              icon: const Icon(Icons.slow_motion_video_rounded,
                                  size: 20),
                              label: const Text('천천히 듣기')),
                        ]),
                        if (speech.message != null)
                          Semantics(
                              liveRegion: true,
                              child: Text(speech.message!,
                                  style: const TextStyle(
                                      fontSize: 12, color: muted))),
                      ])),
          const SizedBox(height: 10),
          Text(word.note),
          if (word.exampleCredit != null) ...[
            const SizedBox(height: 10),
            Text(word.exampleCredit!,
                style: const TextStyle(fontSize: 10, color: muted)),
          ],
          if (!correct!) ...[
            const SizedBox(height: 10),
            const Text('복습 목록에 저장했어요.', style: TextStyle(color: teal))
          ],
          const SizedBox(height: 12),
          xpChange(exercises[index]),
        ]));
  }

  @override
  Widget build(BuildContext context) {
    final exercise = exercises[index];
    final word = exercise.word;
    final focus = WordCues.translationFocus(word);
    final focusStart = focus == null ? -1 : word.translation.indexOf(focus);
    return Scaffold(
        // No app bar: the screen must fit with the keyboard. System back (or
        // the iOS edge swipe) and the small back button below leave.
        body: Column(children: [
      Expanded(
          child: PageBody(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 2),
              children: [
            if (finished) ...[
              const SizedBox(height: 35),
              const Center(
                  child: PuppyMascot(size: 156, pose: PuppyPose.happy)),
              const SizedBox(height: 24),
              const TitleText('한 걸음 더 가까워졌어요!'),
              const SizedBox(height: 16),
              Text(
                  '${exercises.length}문제 중 $hits문제 정답 · 현재 Lv. ${widget.state.level}'),
              const SizedBox(height: 12),
              const Text('틀린 단어는 복습에 저장했어요.\n다음번에는 조금 더 익숙해질 거예요.'),
              const SizedBox(height: 28),
              ActionButton('단어 계속하기', onPressed: continuePractice),
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('학습 화면으로')),
            ] else ...[
              Align(
                  alignment: Alignment.centerLeft,
                  child: BackButton(
                      style: IconButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(32, 32)))),
              Row(children: [
                Expanded(
                    child: Tag(exercise.label(DateTime.now()),
                        warm: exercise.oftenMissed)),
                Text('${index + 1} / ${exercises.length}',
                    style: const TextStyle(
                        color: teal, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                  value: index / exercises.length,
                  backgroundColor: const Color(0xFFE4EBE2),
                  minHeight: 5),
              const SizedBox(height: 10),
              Panel(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    WordIndicators(word: word),
                    const SizedBox(height: 10),
                    Text(vm.dialogue.situation,
                        key: const ValueKey('dialogue-situation'),
                        style: const TextStyle(
                            color: teal,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    _partnerTurn(),
                    const SizedBox(height: 10),
                    DialogueTurn(
                        speaker: vm.cast.learner,
                        reply: true,
                        english: ClozeSentence(
                            key: ValueKey('${word.id}-$index'),
                            sentence: word.sentence,
                            answer: word.answer,
                            controller: input,
                            readOnly: correct != null,
                            onChanged: _onInput,
                            onSubmitted: submit,
                            fitLines: 1,
                            maxFontSize: 18,
                            keys: keys),
                        translation: Text.rich(
                            TextSpan(children: [
                              if (focusStart < 0)
                                TextSpan(text: word.translation)
                              else ...[
                                TextSpan(
                                    text: word.translation
                                        .substring(0, focusStart)),
                                TextSpan(
                                    text: focus,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: teal,
                                        backgroundColor: mint)),
                                TextSpan(
                                    text: word.translation
                                        .substring(focusStart + focus!.length)),
                              ],
                            ]),
                            key: const ValueKey('question-translation'),
                            style: const TextStyle(
                                fontSize: 15, height: 1.4, color: ink))),
                    if (correct == null) ...[
                      const SizedBox(height: 10),
                      _guide(),
                    ],
                    if (focus == null && word.meaning != null) ...[
                      const SizedBox(height: 8),
                      Text('학습할 뜻: ${word.meaning}',
                          style: const TextStyle(
                              color: teal, fontWeight: FontWeight.w700)),
                    ],
                  ])),
              const SizedBox(height: 4),
              if (correct == null)
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  TextButton(
                      onPressed: vm.hintVisible ? null : vm.showHint,
                      child: const Text('힌트 보기')),
                  const SizedBox(width: 12),
                  TextButton(
                      onPressed: () => grade(false),
                      child: const Text('정답 보기')),
                ])
              else ...[
                if (!_revealed) feedback(),
                if (_revealed)
                  TextButton(
                      onPressed: showAnswer, child: const Text('해설 다시 보기')),
                const SizedBox(height: 18),
                ActionButton(
                    index == exercises.length - 1 ? '학습 결과 보기' : '다음 문제',
                    onPressed: next),
              ],
            ],
          ])),
      if (!finished && correct == null)
        CompactKeyboard(
            onKey: keys.type, onBackspace: keys.backspace, onDone: submit),
    ]));
  }

  Widget _partnerTurn() => DialogueTurn(
      speaker: vm.cast.partner,
      english: Text(vm.dialogue.english,
          key: const ValueKey('dialogue-partner-english'),
          style: const TextStyle(fontSize: 18, height: 1.4, color: ink)),
      translation: Text(vm.dialogue.korean,
          key: const ValueKey('dialogue-partner-translation'),
          style: const TextStyle(fontSize: 15, height: 1.4, color: muted)));
}
