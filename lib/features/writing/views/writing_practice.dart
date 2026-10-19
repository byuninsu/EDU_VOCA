import 'dart:async';
import 'dart:io';
import '../view_models/writing_view_model.dart';
import 'package:flutter/material.dart';
import 'package:edu_voca/data/services/gemini_writing_evaluator.dart';
import 'package:edu_voca/domain/models/scenario.dart';
import 'package:edu_voca/domain/models/writing_feedback.dart';
import 'package:edu_voca/domain/services/writing_evaluator.dart';
import 'package:edu_voca/features/learning/view_models/learning_view_model.dart';
import 'package:edu_voca/features/learning/view_models/sentence_speech_view_model.dart';
import 'package:edu_voca/shared/widgets/ui.dart';

/// Gemini on Android with an offline fallback; offline check elsewhere.
WritingEvaluator defaultWritingEvaluator() => Platform.isAndroid
    ? FallbackWritingEvaluator(
        GeminiWritingEvaluator(), const OfflineWritingEvaluator())
    : const OfflineWritingEvaluator();

class WritingPractice extends StatefulWidget {
  final LearningViewModel state;
  final Scenario scenario;
  final WritingEvaluator? evaluator;
  final SentenceSpeechViewModel? speech;

  /// Exchange to start from, e.g. the one saved for review.
  final int startTurn;
  const WritingPractice(
      {super.key,
      required this.state,
      required this.scenario,
      this.evaluator,
      this.speech,
      this.startTurn = 0});
  @override
  State<WritingPractice> createState() => _WritingPracticeState();
}

class _WritingPracticeState extends State<WritingPractice>
    with WidgetsBindingObserver {
  final input = TextEditingController();
  late final speech = widget.speech ?? SentenceSpeechViewModel();
  late final WritingViewModel vm = WritingViewModel(
      learning: widget.state,
      scenario: widget.scenario,
      evaluator: widget.evaluator ?? defaultWritingEvaluator(),
      turn: widget.startTurn.clamp(0, widget.scenario.turns.length - 1));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    vm.addListener(_refresh);
    _openTurn();
  }

  /// The other person speaks first in every exchange.
  void _openTurn() {
    speech.prepare(vm.current.example);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) speech.speak(vm.current.partner);
    });
  }

  void _next() {
    input.clear();
    vm.advance();
    _openTurn();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) speech.stop();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    vm.removeListener(_refresh);
    vm.dispose();
    speech.dispose();
    input.dispose();
    super.dispose();
  }

  Future<void> _evaluate() async {
    FocusScope.of(context).unfocus();
    unawaited(speech.stop());
    await vm.evaluate(input.text);
    if (mounted && vm.feedback != null && vm.error == null) await _showResult();
  }

  Future<void> _reveal() async {
    FocusScope.of(context).unfocus();
    vm.reveal(input.text);
    await _showResult();
  }

  /// The result appears as a popup and reads its sentence once.
  Future<void> _showResult() async {
    final line = vm.lineToSpeak;
    if (line != null) unawaited(speech.speak(line));
    final done = vm.done;
    final action = await showDialog<String>(
        context: context,
        builder: (dialogContext) => Dialog(
            backgroundColor: paper,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
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
                      Flexible(child: SingleChildScrollView(child: _result())),
                      const SizedBox(height: 16),
                      if (done) ...[
                        vm.isLastTurn
                            ? ActionButton('연습 마치기',
                                onPressed: () =>
                                    Navigator.pop(dialogContext, 'finish'))
                            : ActionButton('다음 대화로 →',
                                onPressed: () =>
                                    Navigator.pop(dialogContext, 'next')),
                        TextButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext, 'again'),
                            child: const Text('다른 표현으로 다시 써보기')),
                      ] else ...[
                        ActionButton('다시 써 볼게요',
                            onPressed: () => Navigator.pop(dialogContext)),
                        TextButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext, 'reveal'),
                            child: const Text('예시 답안 보기')),
                      ],
                    ])))));
    unawaited(speech.stop());
    if (!mounted) return;
    switch (action) {
      case 'finish':
        Navigator.pop(context);
      case 'next':
        _next();
      case 'again':
        _tryAgain();
      case 'reveal':
        await _reveal();
    }
  }

  void _tryAgain() {
    unawaited(speech.stop());
    vm.tryAgain();
  }

  Widget _listen(String text, {String label = '듣기'}) => TextButton.icon(
      onPressed: () => speech.speak(text),
      icon: const Icon(Icons.volume_up_rounded, size: 20),
      label: Text(label));

  Widget _result() {
    final feedback = vm.feedback;
    final s = vm.current;
    final (title, color, pose) = vm.revealed
        ? ('예시 답안을 확인해요', const Color(0xFFFFEEDB), PuppyPose.studying)
        : switch (feedback!.grade) {
            WritingGrade.veryGood => ('Very good! 🎉', mint, PuppyPose.happy),
            WritingGrade.good => ('Good 👍', mint, PuppyPose.studying),
            WritingGrade.retry => (
                '다시 해볼까요?',
                const Color(0xFFFFEEDB),
                PuppyPose.disappointed
              ),
          };
    final better = vm.lineToSpeak;
    return Panel(
        key: const ValueKey('writing-result'),
        color: color,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            PuppyMascot(size: 56, pose: pose),
            const SizedBox(width: 10),
            Expanded(child: TitleText(title, size: 20)),
          ]),
          if (feedback != null && !vm.revealed) ...[
            const SizedBox(height: 10),
            Text(feedback.comment),
          ],
          if (better != null) ...[
            const SizedBox(height: 14),
            Label(feedback?.grade == WritingGrade.veryGood && !vm.revealed
                ? '내 문장'
                : 'Very good 표현'),
            const SizedBox(height: 8),
            TitleText(better, size: 20),
            _listen(better),
            if (better != s.example) ...[
              const SizedBox(height: 6),
              const Label('다른 표현 예시'),
              const SizedBox(height: 6),
              Text(s.example, style: const TextStyle(fontSize: 17, color: ink)),
              _listen(s.example),
            ],
            const SizedBox(height: 6),
            Text(s.tip, style: const TextStyle(fontSize: 13)),
          ],
          if (vm.saved) ...[
            const SizedBox(height: 10),
            const Text('복습 목록에 저장했어요.', style: TextStyle(color: teal)),
          ],
          if (feedback?.offline == true) ...[
            const SizedBox(height: 10),
            const Text('AI 평가를 사용할 수 없어 예시 답안과 비교한 간이 평가예요.',
                style: TextStyle(fontSize: 11, color: muted)),
          ],
        ]));
  }

  /// Earlier exchanges open in a sheet so the main screen stays short.
  void _showHistory() => showModalBottomSheet<void>(
      context: context,
      backgroundColor: paper,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
          child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(sheetContext).size.height * .7),
              child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  children: [
                    const Label('이전 대화'),
                    const SizedBox(height: 12),
                    for (var i = 0; i < vm.turn; i++) ...[
                      _bubble(widget.scenario.turns[i].partner, mine: false),
                      _bubble(vm.replies[i], mine: true),
                      const SizedBox(height: 6),
                    ],
                  ]))));

  Widget _bubble(String text, {required bool mine}) => Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
          constraints: const BoxConstraints(maxWidth: 300),
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
              color: mine ? mint : Colors.white,
              border: Border.all(color: mine ? mint : warmLine),
              borderRadius: BorderRadius.circular(18)),
          child: Text(text, style: const TextStyle(fontSize: 14, color: ink))));

  @override
  Widget build(BuildContext context) {
    final s = widget.scenario;
    final step = vm.current;
    final done = vm.done;
    final total = s.turns.length;
    return Scaffold(
        appBar: AppBar(title: Text('${s.emoji}  ${s.title}')),
        body: PageBody(children: [
          Row(children: [
            Expanded(child: Tag('대화 ${vm.turn + 1} / $total')),
            Text(s.subtitle,
                style: const TextStyle(fontSize: 12, color: muted)),
          ]),
          const SizedBox(height: 10),
          LinearProgressIndicator(
              value: (vm.turn + (done ? 1 : 0)) / total,
              backgroundColor: const Color(0xFFE4EBE2),
              minHeight: 5),
          const SizedBox(height: 16),
          Panel(
              key: ValueKey('partner-${vm.turn}'),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Label('상대방'),
                    const SizedBox(height: 10),
                    Text(step.partner,
                        style: const TextStyle(
                            fontSize: 20, color: ink, height: 1.5)),
                    _listen(step.partner, label: '다시 듣기'),
                  ])),
          const SizedBox(height: 16),
          Panel(
              color: mint,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Label('이렇게 말하고 싶어요'),
                    const SizedBox(height: 12),
                    TitleText(step.prompt, size: 20),
                  ])),
          const SizedBox(height: 24),
          TextField(
              controller: input,
              minLines: 2,
              maxLines: 5,
              readOnly: done || vm.evaluating,
              keyboardType: TextInputType.multiline,
              autocorrect: false,
              decoration: InputDecoration(
                  labelText: '나의 영어 대답',
                  hintText: 'Write your answer here...',
                  errorText: vm.error)),
          const SizedBox(height: 18),
          if (!done) ...[
            vm.evaluating
                ? const Center(
                    child: Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator()))
                : ActionButton(vm.attempts == 0 ? '대답하기' : '다시 대답하기',
                    onPressed: _evaluate),
            if (vm.attempts > 0 && !vm.evaluating)
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                TextButton(
                    onPressed: _showResult, child: const Text('피드백 다시 보기')),
                TextButton(onPressed: _reveal, child: const Text('예시 답안 보기')),
              ]),
          ] else ...[
            TextButton(onPressed: _showResult, child: const Text('결과 다시 보기')),
            vm.isLastTurn
                ? ActionButton('연습 마치기',
                    onPressed: () => Navigator.pop(context))
                : ActionButton('다음 대화로 →', onPressed: _next),
            const SizedBox(height: 8),
            TextButton(
                onPressed: _tryAgain, child: const Text('다른 표현으로 다시 써보기')),
          ],
          if (vm.turn > 0)
            Center(
                child: TextButton.icon(
                    onPressed: _showHistory,
                    icon: const Icon(Icons.forum_outlined, size: 18),
                    label: Text('이전 대화 보기 (${vm.turn})'))),
        ]));
  }
}
