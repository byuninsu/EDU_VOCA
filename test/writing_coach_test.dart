import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edu_voca/domain/models/writing_feedback.dart';
import 'package:edu_voca/domain/services/writing_evaluator.dart';
import 'package:edu_voca/features/writing/view_models/writing_view_model.dart';
import 'package:edu_voca/features/writing/views/writing_practice.dart';
import 'support.dart';
import 'widget_test.dart' show phone;

Future<void> show(WidgetTester tester, String text) async {
  if (find.text(text).evaluate().isNotEmpty) {
    await tester.ensureVisible(find.text(text));
    await tester.pumpAndSettle();
  } else {
    await tester.scrollUntilVisible(find.text(text), 120,
        scrollable: find.byType(Scrollable).first);
  }
}

Future<void> tapText(WidgetTester tester, String text) async {
  await show(tester, text);
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

class ScriptedEvaluator implements WritingEvaluator {
  final List<WritingFeedback> results;
  final answers = <String>[];
  Completer<void>? gate;
  ScriptedEvaluator(this.results);
  @override
  Future<WritingFeedback> evaluate(
      Scenario scenario, int turn, String answer) async {
    answers.add(answer);
    if (gate != null) await gate!.future;
    return results.removeAt(0);
  }
}

class BrokenEvaluator implements WritingEvaluator {
  @override
  Future<WritingFeedback> evaluate(
          Scenario scenario, int turn, String answer) =>
      Future.error(StateError('offline'));
}

Finder inDialog(String text) =>
    find.descendant(of: find.byType(Dialog), matching: find.text(text));

void main() {
  const channel = MethodChannel('flutter_tts');
  final spoken = <String>[];
  setUp(() {
    spoken.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'speak') {
        final a = call.arguments;
        spoken.add('${a is Map ? a['text'] : a}');
      }
      return call.method == 'isLanguageAvailable' ? true : 1;
    });
  });
  tearDown(() => TestDefaultBinaryMessengerBinding
      .instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, null));

  final hotel = scenarios.first;

  test('Offline check grades exact, close and unrelated replies', () async {
    const offline = OfflineWritingEvaluator();
    for (final reply in [
      'i have a reservation under Daniel',
      'I have a reservation under Jiwoo Lee!',
      "I've a reservation under the name Daniel.",
      'I made a reservation. My name is Daniel.',
    ]) {
      final r = await offline.evaluate(hotel, 0, reply);
      expect(r.grade, isNot(WritingGrade.retry), reason: reply);
      expect(r.offline, isTrue);
    }
    final exact = await offline.evaluate(
        hotel, 0, 'I have a reservation under Daniel.');
    expect(exact.grade, WritingGrade.veryGood);
    final close = await offline.evaluate(hotel, 0, 'I have reservation.');
    expect(close.grade, WritingGrade.good);
    expect(close.betterAnswer, hotel.turns.first.example);
    final far = await offline.evaluate(hotel, 0, 'Hello, nice to meet you.');
    expect(far.grade, WritingGrade.retry);
    expect(far.comment, contains('"'));
    expect(far.betterAnswer, isEmpty);
  });

  test('AI failure falls back to the offline check', () async {
    final fallback = FallbackWritingEvaluator(
        BrokenEvaluator(), const OfflineWritingEvaluator());
    final result = await fallback.evaluate(hotel, 0, 'I have reservation.');
    expect(result.offline, isTrue);
    final ai = FallbackWritingEvaluator(
        ScriptedEvaluator([const WritingFeedback(WritingGrade.good, 'ok')]),
        const OfflineWritingEvaluator());
    expect((await ai.evaluate(hotel, 0, 'x')).offline, isFalse);
  });

  test('Retry is unlimited; good saves the turn for review', () async {
    final learning = createLearning();
    final vm = WritingViewModel(
        learning: learning,
        scenario: hotel,
        evaluator: ScriptedEvaluator([
          const WritingFeedback(WritingGrade.retry, 'hint'),
          const WritingFeedback(WritingGrade.retry, 'hint'),
          const WritingFeedback(WritingGrade.good, 'fix',
              betterAnswer: 'I have a reservation.'),
          const WritingFeedback(WritingGrade.veryGood, 'great'),
        ]));
    await vm.evaluate('  ');
    expect(vm.error, isNotNull);
    await vm.evaluate('Hello');
    await vm.evaluate('Hi');
    expect(vm.attempts, 2);
    expect(vm.done, isFalse);
    expect(vm.lineToSpeak, isNull);
    await vm.evaluate('I have reservation');
    expect(vm.done, isTrue);
    expect(vm.lineToSpeak, 'I have a reservation.');
    expect(learning.writingReviews['hotel'], '0\tI have reservation');
    expect(Scenario.parseReview(learning.writingReviews['hotel']!),
        (0, 'I have reservation'));
    vm.tryAgain();
    await vm.evaluate('I have a reservation.');
    expect(vm.lineToSpeak, 'I have a reservation.');
    vm.dispose();
    learning.dispose();
  });

  test('Five exchanges continue in order; a clean run clears the review',
      () async {
    final learning = createLearning();
    final vm = WritingViewModel(learning: learning, scenario: hotel);
    expect(hotel.turns, hasLength(5));
    vm.advance(); // Nothing settled yet: stays on the first exchange.
    expect(vm.turn, 0);
    for (var i = 0; i < hotel.turns.length; i++) {
      expect(vm.current, same(hotel.turns[i]));
      await vm.evaluate(hotel.turns[i].example);
      expect(vm.feedback!.grade, WritingGrade.veryGood, reason: '$i');
      expect(vm.isLastTurn, i == hotel.turns.length - 1);
      vm.advance();
    }
    expect(vm.turn, hotel.turns.length - 1);
    expect(vm.replies, hotel.turns.take(4).map((t) => t.example).toList());
    expect(learning.writingReviews, isEmpty);
    // Reviewing a saved turn starts there, with earlier model replies shown.
    final review =
        WritingViewModel(learning: learning, scenario: hotel, turn: 2);
    expect(review.current, same(hotel.turns[2]));
    expect(review.replies, hotel.turns.take(2).map((t) => t.example).toList());
    vm.dispose();
    review.dispose();
    learning.dispose();
  });

  test('Every scenario has five complete exchanges', () {
    expect(scenarios.length, greaterThanOrEqualTo(6));
    for (final scenario in scenarios) {
      expect(scenario.turns, hasLength(5), reason: scenario.id);
      for (final turn in scenario.turns) {
        expect([
          turn.partner,
          turn.prompt,
          turn.example,
          turn.tip
        ], everyElement(isNotEmpty), reason: scenario.id);
        expect(turn.alternatives, isNotEmpty, reason: turn.example);
      }
    }
  });

  testWidgets('Last exchange: partner speaks first; very good finishes',
      (tester) async {
    phone(tester);
    final learning = createLearning();
    addTearDown(learning.dispose);
    final evaluator = ScriptedEvaluator([
      const WritingFeedback(WritingGrade.veryGood, '자연스러워요!',
          betterAnswer: 'It was delicious. Could we get the check, please?')
    ]);
    await tester.pumpWidget(MaterialApp(
        home: const Scaffold(),
        routes: {
          '/w': (_) => WritingPractice(
              state: learning,
              scenario: scenarios[1],
              evaluator: evaluator,
              startTurn: 4)
        },
        initialRoute: '/w'));
    await tester.pumpAndSettle();
    expect(spoken, [scenarios[1].turns[4].partner]);
    expect(find.text('대화 5 / 5'), findsOneWidget);
    await tester.enterText(
        find.byType(TextField), 'it was delicious could we get the check');
    await tapText(tester, '대답하기');
    expect(evaluator.answers, ['it was delicious could we get the check']);
    // The result is a popup over the conversation.
    expect(inDialog('Very good! 🎉'), findsOneWidget);
    expect(inDialog('자연스러워요!'), findsOneWidget);
    expect(spoken.last, 'It was delicious. Could we get the check, please?');
    await tester.tap(inDialog('연습 마치기'));
    await tester.pumpAndSettle();
    expect(find.byType(WritingPractice), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Good shows the very good sentence; leaving mid-check is safe',
      (tester) async {
    phone(tester);
    final learning = createLearning();
    addTearDown(learning.dispose);
    final evaluator = ScriptedEvaluator([
      const WritingFeedback(WritingGrade.good, '관사 a를 넣어요.',
          betterAnswer: 'I have a reservation under Daniel.'),
      const WritingFeedback(WritingGrade.good, 'late'),
    ]);
    await tester.pumpWidget(MaterialApp(
        home: WritingPractice(
            state: learning, scenario: hotel, evaluator: evaluator)));
    await tester.enterText(find.byType(TextField), 'I have reservation');
    await tapText(tester, '대답하기');
    expect(inDialog('Good 👍'), findsOneWidget);
    expect(inDialog('Very good 표현'), findsOneWidget);
    expect(inDialog('I have a reservation under Daniel.'), findsOneWidget);
    expect(spoken.last, 'I have a reservation under Daniel.');
    expect(inDialog('복습 목록에 저장했어요.'), findsOneWidget);
    await tester.tap(inDialog('다른 표현으로 다시 써보기'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    evaluator.gate = Completer<void>();
    await show(tester, '대답하기');
    await tester.tap(find.text('대답하기'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    evaluator.gate!.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Popup moves to the next exchange; earlier lines open on demand',
      (tester) async {
    phone(tester);
    final learning = createLearning();
    addTearDown(learning.dispose);
    final evaluator = ScriptedEvaluator([
      const WritingFeedback(WritingGrade.veryGood, '좋아요!',
          betterAnswer: 'I have a reservation under Daniel.'),
      const WritingFeedback(WritingGrade.good, '조금만 고쳐요.',
          betterAnswer: "Yes, that's right. I'll check out on Friday."),
    ]);
    await tester.pumpWidget(MaterialApp(
        home: WritingPractice(
            state: learning, scenario: hotel, evaluator: evaluator)));
    await tester.pumpAndSettle();
    expect(find.text('대화 1 / 5'), findsOneWidget);
    await tester.enterText(
        find.byType(TextField), 'I have a reservation under Daniel');
    await tapText(tester, '대답하기');
    await tester.tap(inDialog('다음 대화로 →'));
    await tester.pumpAndSettle();
    expect(find.text('대화 2 / 5'), findsOneWidget);
    expect(find.text(hotel.turns[1].partner), findsOneWidget);
    expect(spoken.last, hotel.turns[1].partner);
    // Earlier lines are not on the main screen; a button opens them.
    expect(find.text(hotel.turns[0].partner), findsNothing);
    await tapText(tester, '이전 대화 보기 (1)');
    expect(find.text(hotel.turns[0].partner), findsOneWidget);
    expect(find.text('I have a reservation under Daniel.'), findsOneWidget);
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    expect(find.text(hotel.turns[0].partner), findsNothing);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty);
    await tester.enterText(find.byType(TextField), 'Yes. I check out Friday');
    await tapText(tester, '대답하기');
    expect(inDialog('Good 👍'), findsOneWidget);
    expect(Scenario.parseReview(learning.writingReviews['hotel']!),
        (1, 'Yes. I check out Friday'));
    expect(tester.takeException(), isNull);
  });
}
