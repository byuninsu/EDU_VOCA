import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edu_voca/app/app.dart';
import 'package:edu_voca/shared/widgets/ui.dart';
import 'package:edu_voca/features/learning/views/word_practice.dart';
import 'support.dart';
import 'puppy_design_test.dart' show prepare, capture, tapText;

Finder pose(PuppyPose value) => find.byWidgetPredicate(
    (widget) => widget is PuppyMascot && widget.pose == value);

Future<void> practice(WidgetTester tester, {GlobalKey? boundary}) async {
  PaintingBinding.instance.imageCache.clear();
  PaintingBinding.instance.imageCache.clearLiveImages();
  await prepare(tester);
  final state = createLearning();
  addTearDown(state.dispose);
  await tester.pumpWidget(RepaintBoundary(
      key: boundary,
      child: MaterialApp(
          theme: ThemeData(fontFamily: 'Preview'),
          home: WordPractice(
              state: state,
              exercises: [Exercise(wordsById['water']!)],
              countsToday: true))));
}

void main() {
  testWidgets('Every supplied pose decodes in its display slot',
      (tester) async {
    await prepare(tester);
    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
        key: key,
        child: MaterialApp(
            home: Scaffold(
                backgroundColor: paper,
                body: Wrap(children: [
                  for (final value in PuppyPose.values)
                    PuppyMascot(size: 120, pose: value),
                ])))));
    await capture(tester, key, 'puppy-poses');
    expect(tester.takeException(), isNull);
  });
  testWidgets('Home switches from cards to celebration after daily goal',
      (tester) async {
    await prepare(tester);
    final state = createLearning(completed: 10);
    await tester.pumpWidget(DailyEnglishApp(state: state));
    expect(pose(PuppyPose.happy), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });
  testWidgets('Retry thinks and reveal shows consolation', (tester) async {
    await practice(tester);
    expect(pose(PuppyPose.cards), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'zzz');
    await submitAnswer(tester);
    expect(pose(PuppyPose.thinking), findsOneWidget);
    await tapText(tester, '정답 보기');
    expect(pose(PuppyPose.disappointed), findsOneWidget);
  });
  testWidgets('Correct celebrates and completion dialog continues practice',
      (tester) async {
    final key = GlobalKey();
    await practice(tester, boundary: key);
    await tester.enterText(find.byType(TextField), 'water');
    await submitAnswer(tester);
    expect(pose(PuppyPose.happy), findsOneWidget);
    await tapText(tester, '확인');
    expect(find.byType(Dialog), findsOneWidget);
    await capture(tester, key, 'puppy-completion-dialog');
    await tester.tap(find.descendant(
        of: find.byType(Dialog), matching: find.text('단어 계속하기')));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(pose(PuppyPose.cards), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Hint assisted solution encourages studying', (tester) async {
    await practice(tester);
    await tapText(tester, '힌트 보기');
    expect(pose(PuppyPose.thinking), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'water');
    await submitAnswer(tester);
    expect(pose(PuppyPose.studying), findsOneWidget);
    expect(pose(PuppyPose.disappointed), findsNothing);
  });
}
