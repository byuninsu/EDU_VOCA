import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edu_voca/data/local/dialogue_contexts.dart';
import 'package:edu_voca/features/learning/views/word_practice.dart';
import 'package:edu_voca/features/learning/view_models/word_practice_view_model.dart';
import 'package:edu_voca/shared/widgets/ui.dart';
import 'package:edu_voca/shared/widgets/dialogue_turn.dart' as chat;
import 'support.dart';
import 'puppy_design_test.dart' show prepare, capture, tapText;

void main() {
  test(
      'Every vocabulary entry has bilingual dialogue; phrases have authored scenes',
      () {
    for (final word in playableWords) {
      final context = dialogueContextFor(word);
      expect(context.situation, isNotEmpty, reason: word.id);
      expect(context.english, isNotEmpty, reason: word.id);
      expect(context.english, isNot(contains('____')), reason: word.id);
      expect(RegExp('[가-힣]').hasMatch(context.korean), isTrue, reason: word.id);
      expect(word.sentence.split('____'), hasLength(2), reason: word.id);
      if (word.isPhrase) {
        expect(dialogueContexts.containsKey(word.id), isTrue, reason: word.id);
        expect(context.english.toLowerCase(),
            isNot(contains(word.answer.toLowerCase())),
            reason: word.id);
      }
    }
  });

  test(
      'Dialogue changes with question and keeps the original answer and review identity',
      () {
    final state = createLearning();
    final vm = WordPracticeViewModel(
        learning: state,
        exercises: [
          Exercise(wordsById['water']!),
          Exercise(wordsById['checkin']!)
        ],
        countsToday: true);
    expect(vm.completeDialogue,
        'What would you like to drink?\nCan I have some water?');
    final firstCast = vm.cast;
    vm.submit('water');
    expect(identical(vm.cast, firstCast), isTrue);
    expect(vm.correct, isTrue);
    expect(state.learned, contains('water'));
    vm.next();
    expect(
        {vm.cast.partner, vm.cast.learner}
            .intersection({firstCast.partner, firstCast.learner}),
        isEmpty);
    expect(vm.dialogue.situation, '호텔 프런트에서');
    vm.reveal();
    expect(state.reviews, contains('checkin'));
    expect(state.completed, 2);
    vm.dispose();
    state.dispose();
  });

  testWidgets(
      'Word conversation shows both translations and reveals only after grading',
      (tester) async {
    await prepare(tester);
    final state = createLearning();
    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
        key: key,
        child: MaterialApp(
            theme: ThemeData(fontFamily: 'Preview', colorSchemeSeed: teal),
            home: WordPractice(
                state: state,
                exercises: [Exercise(wordsById['water']!)],
                countsToday: true))));
    await tester.pumpAndSettle();
    final names = tester
        .widgetList<chat.DialogueTurn>(find.byType(chat.DialogueTurn))
        .map((turn) => turn.speaker)
        .toList();
    expect(names.toSet(), hasLength(2));
    expect(find.text('What would you like to drink?'), findsOneWidget);
    expect(find.text('무엇을 마시고 싶으세요?'), findsOneWidget);
    expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('question-translation')))
            .textSpan!
            .toPlainText(),
        wordsById['water']!.translation);
    expect(find.text('water'), findsNothing);
    await capture(tester, key, 'dialogue-word');
    await tester.enterText(find.byType(TextField), 'water');
    await tester.pumpAndSettle();
    final dialog = find.byType(Dialog);
    expect(find.descendant(of: dialog, matching: find.text(names[0])),
        findsOneWidget);
    expect(find.descendant(of: dialog, matching: find.text(names[1])),
        findsOneWidget);
    expect(find.text('대화 듣기'), findsOneWidget);
    expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('answer-sentence')))
            .textSpan!
            .toPlainText(),
        wordsById['water']!.complete);
    await capture(tester, key, 'dialogue-answer');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });

  testWidgets(
      'Phrase conversation retains all editable words and a coherent scene',
      (tester) async {
    await prepare(tester);
    final state = createLearning();
    await tester.pumpWidget(MaterialApp(
        home: WordPractice(
            state: state,
            exercises: [Exercise(wordsById['checkin']!)],
            countsToday: true)));
    expect(find.text('호텔 프런트에서'), findsOneWidget);
    expect(
        find.text('Welcome to our hotel. How can I help you?'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('check in'), findsNothing);
    await tester.enterText(find.byType(TextField).first, 'check in');
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(state.correctToday, 1);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });

  testWidgets('Long dialogue scrolls on small screens with large text',
      (tester) async {
    await prepare(tester, width: 320);
    tester.view.physicalSize = const Size(320, 640);
    final state = createLearning();
    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
        key: key,
        child: MaterialApp(
            theme: ThemeData(fontFamily: 'Preview', colorSchemeSeed: teal),
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(1.6)),
                child: child!),
            home: WordPractice(
                state: state,
                exercises: [Exercise(wordsById['onceinabluemoon']!)],
                countsToday: true))));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byType(TextField).first, 120,
        scrollable: find.byType(Scrollable).first);
    expect(tester.takeException(), isNull);
    await capture(tester, key, 'dialogue-small');
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
}
