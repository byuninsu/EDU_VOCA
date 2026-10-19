import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edu_voca/features/learning/views/word_practice.dart';
import 'package:edu_voca/shared/widgets/ui.dart';
import 'package:edu_voca/domain/services/word_cues.dart';
import 'support.dart';
import 'puppy_design_test.dart' show prepare, tapText;

void main() {
  for (final id in ['atfirst']) {
    testWidgets(
        'Reveal $id highlights only blank and can reopen without regrading',
        (tester) async {
      await prepare(tester);
      final state = createLearning();
      final word = wordsById[id]!;
      await tester.pumpWidget(MaterialApp(
          home: WordPractice(
              state: state,
              exercises: [Exercise(word), Exercise(wordsById['help']!)],
              countsToday: true)));
      expect(find.text('품사: 부사구'), findsOneWidget);
      final translation = tester
          .widget<Text>(find.byKey(const ValueKey('question-translation')));
      final highlights =
          (translation.textSpan! as TextSpan).children!.cast<TextSpan>();
      expect(
          highlights
              .where((s) => s.style?.backgroundColor == mint)
              .map((s) => s.text),
          ['처음에는']);
      await tapText(tester, '정답 보기');
      expect(find.byType(Dialog), findsOneWidget);
      final text =
          tester.widget<Text>(find.byKey(const ValueKey('answer-sentence')));
      expect(text.textSpan!.toPlainText(), word.complete);
      final spans = (text.textSpan! as TextSpan).children!.cast<TextSpan>();
      expect(
          spans
              .where((s) => s.style?.backgroundColor == mint)
              .map((s) => s.text),
          [word.answer]);
      expect(state.completed, 1);
      expect(state.reviews.containsKey(word.id), isTrue);
      await tester.tap(find.byTooltip('닫기'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('answer-sentence')), findsNothing);
      await tapText(tester, '해설 다시 보기');
      expect(state.completed, 1);
      await tester.tap(
          find.descendant(of: find.byType(Dialog), matching: find.text('확인')));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(find.text('2 / 2'), findsOneWidget);
      expect(find.text('해설 다시 보기'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      state.dispose();
    });
  }
  testWidgets('Final reveal transitions to completion dialog', (tester) async {
    await prepare(tester);
    final state = createLearning();
    await tester.pumpWidget(MaterialApp(
        home: WordPractice(
            state: state,
            exercises: [Exercise(wordsById['water']!)],
            countsToday: true)));
    await tapText(tester, '정답 보기');
    await tester.tap(
        find.descendant(of: find.byType(Dialog), matching: find.text('확인')));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('한 걸음 더 성장했어요!'), findsOneWidget);
    expect(find.byKey(const ValueKey('answer-sentence')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });
  testWidgets('Long explanation fits small screen with accessible next action',
      (tester) async {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    await prepare(tester, width: 320);
    final state = createLearning();
    final key = GlobalKey();
    final word = WordItem('long', 1, 'Try ____ now.', '지금 시도하세요.', 'again',
        List.filled(30, '긴 해설을 읽고 기억해요.').join('\n'));
    await tester.pumpWidget(RepaintBoundary(
        key: key,
        child: MaterialApp(
            theme: ThemeData(fontFamily: 'Preview', colorSchemeSeed: teal),
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(1.3)),
                child: child!),
            home: WordPractice(
                state: state,
                exercises: [Exercise(word)],
                countsToday: true))));
    await tapText(tester, '정답 보기');
    expect(
        find
            .descendant(of: find.byType(Dialog), matching: find.text('확인'))
            .hitTestable(),
        findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });
  testWidgets(
      'Wrong answer retries and correct answer opens popup then advances once',
      (tester) async {
    await prepare(tester);
    final state = createLearning();
    await tester.pumpWidget(MaterialApp(
        home: WordPractice(
            state: state,
            exercises: [
              Exercise(wordsById['water']!),
              Exercise(wordsById['help']!)
            ],
            countsToday: true)));
    // No check button or explanations; a full-length answer checks itself.
    expect(find.text('정답 확인'), findsNothing);
    expect(find.textContaining('오답으로 기록'), findsNothing);
    expect(find.textContaining('출처'), findsNothing);
    await tester.enterText(find.byType(TextField), 'wat');
    await tester.pumpAndSettle();
    expect(find.textContaining('조금 더 생각해'), findsNothing);
    await tester.enterText(find.byType(TextField), 'wrong');
    await tester.pumpAndSettle();
    expect(find.textContaining('조금 더 생각해'), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
    expect(state.completed, 0);
    await tester.enterText(find.byType(TextField), 'water');
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byKey(const ValueKey('answer-sentence')), findsOneWidget);
    expect(state.correctToday, 1);
    await tester.tap(
        find.descendant(of: find.byType(Dialog), matching: find.text('확인')));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(find.text('2 / 2'), findsOneWidget);
    expect(state.completed, 1);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });
  test(
      'Every study entry has POS and an existing translation span, including corrected homographs',
      () {
    expect(playableWords.length, 2897);
    for (final word in playableWords) {
      expect(word.partsOfSpeech, isNotEmpty, reason: word.id);
      final focus = WordCues.translationFocus(word);
      expect(focus, isNotNull, reason: word.id);
      expect(word.translation.contains(focus!), isTrue, reason: word.id);
    }
    expect(WordCues.translationFocus(wordsById['rose']!), '장미');
    expect(WordCues.translationFocus(wordsById['found']!), '설립');
    expect(WordCues.translationFocus(wordsById['capital']!), '수도');
    expect(wordsById['found']!.complete, 'They plan to found a new company.');
    expect(wordsById['water']!.partsOfSpeech, contains('명사'));
    expect(wordsById['quickly']!.partsOfSpeech, contains('부사'));
    expect(wordsById['in']!.partsOfSpeech, contains('전치사'));
  });

  testWidgets('Answer shows experience; filling the bar celebrates once',
      (tester) async {
    await prepare(tester);
    final state = createLearning();
    final a1 = playableWords
        .where((w) => w.difficultyStars == 1 && !w.isPhrase)
        .take(6)
        .toList();
    for (final w in a1.take(4)) {
      state.answer(Exercise(w), true, countsToday: false);
    }
    await tester.pumpWidget(MaterialApp(
        home: WordPractice(
            state: state,
            exercises: [Exercise(a1[4]), Exercise(a1[5])],
            countsToday: true)));
    await tester.enterText(find.byType(TextField), a1[4].answer);
    await tester.pumpAndSettle();
    expect(find.text('경험치 +1 · 레벨 업!'), findsOneWidget);
    await tester.tap(find.descendant(
        of: find.byType(Dialog), matching: find.text('확인')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('level-up')), findsOneWidget);
    expect(find.text('Lv. 1 → Lv. 2'), findsOneWidget);
    expect(find.text('0 / 6 XP'), findsOneWidget);
    await tester.tap(find.text('계속하기'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('level-up')), findsNothing);
    expect(state.level, 2);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
