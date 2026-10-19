import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edu_voca/shared/widgets/cloze_sentence.dart';
import 'package:edu_voca/features/learning/views/word_practice.dart';
import 'support.dart';
import 'puppy_design_test.dart' show prepare, capture, tapText;

void main() {
  testWidgets(
      'Phrase has one sized continuous line per word without exposing answer',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: ClozeSentence(
                sentence: 'It was hard ____.', answer: 'at first'))));
    expect(
        tester.getSize(find.byKey(const ValueKey('cloze-answer-line'))).width,
        lessThan(tester
            .getSize(find.byKey(const ValueKey('cloze-answer-line-1')))
            .width));
    expect(find.text('at'), findsNothing);
    expect(find.text('first'), findsNothing);
    expect(find.textContaining('____'), findsNothing);
  });
  testWidgets('Each sentence blank is editable and combined in word order',
      (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: ClozeSentence(
                sentence: 'It was hard ____.',
                answer: 'at first',
                controller: controller))));
    final second = find.byKey(const ValueKey('cloze-input-1'));
    await tester.tap(second);
    await tester.enterText(second, 'first');
    await tester.enterText(find.byKey(const ValueKey('cloze-input-0')), 'at');
    expect(controller.text, 'at first');
    await tester.enterText(second, '');
    expect(controller.text, 'at ');
    controller.clear();
    await tester.pump();
    expect(tester.widget<TextField>(second).controller!.text, isEmpty);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
  testWidgets(
      'Spaces advance and pasted phrases distribute without losing extra words',
      (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: ClozeSentence(
                sentence: 'It was hard ____.',
                answer: 'at first',
                controller: controller))));
    final first = find.byKey(const ValueKey('cloze-input-0'));
    await tester.enterText(first, 'at ');
    await tester.pump();
    expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('cloze-input-1')))
            .focusNode!
            .hasFocus,
        isTrue);
    await tester.enterText(first, 'at first extra');
    await tester.pump();
    expect(controller.text, 'at first extra');
    await tester.enterText(first, 'at first');
    await tester.pump();
    expect(controller.text, 'at first');
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
  testWidgets(
      'Practice removes separate answer box, retries and locks graded blanks',
      (tester) async {
    await prepare(tester);
    final state = createLearning();
    await tester.pumpWidget(MaterialApp(
        home: WordPractice(
            state: state,
            exercises: [
              Exercise(wordsById['atfirst']!),
              Exercise(wordsById['water']!)
            ],
            countsToday: true)));
    expect(find.text('나의 답변'), findsNothing);
    expect(find.byType(TextField), findsNWidgets(2));
    await tester.enterText(
        find.byKey(const ValueKey('cloze-input-0')), 'wrong');
    await submitAnswer(tester);
    expect(state.completed, 0);
    await tester.enterText(
        find.byKey(const ValueKey('cloze-input-0')), 'at first');
    await submitAnswer(tester);
    expect(state.correctToday, 1);
    expect(
        tester
            .widgetList<TextField>(find.byType(TextField, skipOffstage: false))
            .every((f) => f.readOnly),
        isTrue);
    await tapText(tester, '확인');
    expect(find.byType(TextField), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await state.flush();
    state.dispose();
  });
  testWidgets(
      'Long phrase wraps at small width and inline editing remains accessible',
      (tester) async {
    await prepare(tester, width: 320);
    final controller = TextEditingController();
    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
        key: key,
        child: MaterialApp(
            theme: ThemeData(fontFamily: 'Preview'),
            home: Scaffold(
                body: MediaQuery(
                    data: const MediaQueryData(
                        textScaler: TextScaler.linear(1.5)),
                    child: Padding(
                        padding: const EdgeInsets.all(22),
                        child: ClozeSentence(
                            sentence: 'We eat out ____.',
                            answer: 'once in a blue moon',
                            controller: controller)))))));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNWidgets(5));
    await capture(tester, key, 'inline-phrase');
    await tester.enterText(find.byKey(const ValueKey('cloze-input-4')), 'moon');
    expect(controller.text, '    moon');
    controller.selection = const TextSelection.collapsed(offset: 0);
    await tester.pump();
    expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('cloze-input-4')))
            .controller!
            .text,
        'moon');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
}
