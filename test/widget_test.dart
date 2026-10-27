import 'package:edu_voca/features/home/views/home_shell.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edu_voca/app/app.dart';
import 'package:edu_voca/features/learning/views/word_practice.dart';
import 'package:edu_voca/features/writing/views/writing_practice.dart';
import 'package:edu_voca/shared/widgets/word_indicators.dart';
import 'package:edu_voca/shared/widgets/cloze_sentence.dart';
import 'package:edu_voca/shared/widgets/dialogue_turn.dart' as chat;
import 'support.dart';

import 'package:edu_voca/features/vocabulary/views/vocabulary_catalog.dart';
import 'package:edu_voca/shared/widgets/vocabulary_source_footer.dart';

void phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(find.text(text), 180,
      scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Translation emphasis and first-letter hint work in practice',
      (tester) async {
    phone(tester);
    final learning = createLearning();
    await tester.pumpWidget(MaterialApp(
        home: WordPractice(
            state: learning,
            exercises: [Exercise(wordsById['water']!)],
            countsToday: true)));
    final translation = tester.widget<Text>(find.byWidgetPredicate((w) =>
        w is Text &&
        w.textSpan?.toPlainText() == wordsById['water']!.translation));
    final spans =
        (translation.textSpan! as TextSpan).children!.cast<TextSpan>();
    expect(
        spans.any(
            (s) => s.text == '물' && s.style?.fontWeight == FontWeight.w800),
        isTrue);
    await tapText(tester, '힌트 보기');
    expect(find.text("'w'로 시작하는 표현이에요."), findsOneWidget);
    expect(find.widgetWithText(TextField, 'w'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'water');
    await submitAnswer(tester);
    expect(learning.correctToday, 0);
    expect(learning.completed, 1);
    expect(find.text('표현을 완성했어요!\n힌트 사용으로 복습에 저장해요.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await learning.flush();
    learning.dispose();
  });
  testWidgets('Blank is one continuous rule sized by answer and growing input',
      (tester) async {
    phone(tester);
    Future<void> show(String answer, [String input = '']) =>
        tester.pumpWidget(MaterialApp(
            home: Scaffold(
                body: Padding(
                    padding: const EdgeInsets.all(22),
                    child: ClozeSentence(
                        sentence: 'Please ____ now.',
                        answer: answer,
                        input: input)))));
    await show('go');
    final line = find.byKey(const ValueKey('cloze-answer-line'));
    final shortWidth = tester.getSize(line).width;
    final container = tester.widget<Container>(line);
    final border = (container.decoration! as BoxDecoration).border! as Border;
    expect(border.bottom.width, 2);
    expect(border.top.style, BorderStyle.none);
    expect(find.textContaining('____'), findsNothing);
    expect(find.text('go'), findsNothing);
    await show('look forward to');
    expect(tester.getSize(line).width, greaterThan(shortWidth));
    await show('go', 'some longer attempted answer');
    expect(tester.getSize(line).width, greaterThan(shortWidth));
    expect(find.text('some longer attempted answer'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'Long expression wraps on a narrow screen without revealing answer',
      (tester) async {
    phone(tester);
    tester.view.physicalSize = const Size(320, 700);
    final expression = wordsById['onceinabluemoon']!;
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
            data: const MediaQueryData(
                size: Size(320, 700), textScaler: TextScaler.linear(1.6)),
            child: WordPractice(
                state: createLearning(),
                exercises: [Exercise(expression)],
                countsToday: true))));
    await tester.pumpAndSettle();
    expect(find.text(expression.answer), findsNothing);
    expect(find.textContaining('____'), findsNothing);
    final line = find.byKey(const ValueKey('cloze-answer-line'));
    expect(tester.getSize(line).width, lessThanOrEqualTo(232));
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.byType(TextField).first, 180,
        scrollable: find.byType(Scrollable).first);
    await tester.enterText(find.byType(TextField).first, expression.answer);
    await tester.pump();
    expect(tester.takeException(), isNull);
    await submitAnswer(tester);
    expect(find.text(expression.complete), findsWidgets);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Each question shows separate frequency and Oxford difficulty',
      (tester) async {
    phone(tester);
    await tester.pumpWidget(MaterialApp(
        home: WordPractice(
            state: createLearning(),
            exercises: [
              Exercise(wordsById['be']!),
              Exercise(wordsById['thirst']!)
            ],
            countsToday: true)));
    expect(find.textContaining('앱 난이도'), findsNothing);
    expect(find.textContaining('난이도 ★☆☆☆☆ A1'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(5));
    await tapText(tester, '정답 보기');
    await tapText(tester, '다음 문제');
    await tester.scrollUntilVisible(find.byType(WordIndicators), -180,
        scrollable: find.byType(Scrollable).first);
    expect(find.textContaining('앱 난이도'), findsNothing);
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    expect(find.byIcon(Icons.star_border_rounded), findsNWidgets(4));
    await tester.longPress(find.text('일반 빈도'));
    await tester.pumpAndSettle();
    expect(find.textContaining('실제 사용 횟수는 아니에요.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Phone practice flow saves mistakes and shows review',
      (tester) async {
    phone(tester);
    final state = createLearning();
    await tester.pumpWidget(DailyEnglishApp(state: state));
    await tester.pumpAndSettle();
    expect(find.text('daily english'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const ValueKey('home-shortcut-1')));
    await tester.pumpAndSettle();
    await tapText(tester, '단어 연습하기');
    // Sessions may open with a phrase: type into its first blank.
    await tester.enterText(find.byType(TextField).first, 'wrong');
    await tester.tap(find.byKey(const ValueKey('key-확인')));
    await tester.pumpAndSettle();
    expect(state.completed, 0);
    expect(state.reviews, isEmpty);
    expect(find.textContaining('보세요'), findsOneWidget); // retry guidance
    await tapText(tester, '정답 보기');
    expect(state.completed, 1);
    expect(state.reviews.length, 1);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('닫기'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('section-back')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('home-shortcut-3')));
    await tester.pumpAndSettle();
    expect(find.text('다시 풀기 →'), findsOneWidget);
  });
  testWidgets('Writing reveal saves a review', (tester) async {
    phone(tester);
    final state = createLearning();
    await tester.pumpWidget(MaterialApp(
        home: WritingPractice(state: state, scenario: scenarios.first)));
    await tester.enterText(find.byType(TextField), 'Hello.');
    await tapText(tester, '대답하기');
    // A wrong reply opens the feedback popup; its button reveals the example.
    await tester.tap(find.descendant(
        of: find.byType(Dialog), matching: find.text('예시 답안 보기')));
    await tester.pumpAndSettle();
    expect(find.descendant(
        of: find.byType(Dialog), matching: find.text('예시 답안을 확인해요')),
        findsOneWidget);
    expect(state.writingReviews['hotel'], '0\tHello.');
    expect(tester.takeException(), isNull);
  });
  testWidgets('Narrow screen with large text has no overflow', (tester) async {
    phone(tester);
    tester.view.physicalSize = const Size(320, 700);
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
            data: const MediaQueryData(
                size: Size(320, 700), textScaler: TextScaler.linear(1.4)),
            child: HomeShell(state: createLearning()))));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('Capture phone preview with system Korean font', (tester) async {
    phone(tester);
    await tester.runAsync(() async {
      final file = File('C:/Windows/Fonts/malgun.ttf');
      if (await file.exists()) {
        final loader = FontLoader('Preview');
        loader.addFont(file.readAsBytes().then((b) => ByteData.sublistView(b)));
        await loader.load();
        final icons = FontLoader('MaterialIcons');
        icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
        await icons.load();
      }
    });
    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
        key: key,
        child:
            DailyEnglishApp(state: createLearning(), fontFamily: 'Preview')));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('build/previews').create(recursive: true);
      await File('build/previews/home.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  });
  testWidgets('Word feedback cannot increment progress twice', (tester) async {
    phone(tester);
    final state = createLearning();
    await tester.pumpWidget(MaterialApp(
        home: WordPractice(
            state: state,
            exercises: [Exercise(wordsById['love']!)],
            countsToday: true)));
    await tester.enterText(find.byType(TextField), ' LOVE ');
    await submitAnswer(tester);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(state.completed, 1);
    expect(state.correctToday, 1);
  });
  testWidgets(
      'Live blank updates, retries remain ungraded, and practice continues',
      (tester) async {
    phone(tester);
    final state = createLearning(completed: 10);
    await tester.pumpWidget(MaterialApp(
        home: WordPractice(
            state: state,
            exercises: [Exercise(wordsById['love']!)],
            countsToday: true)));
    for (final value in ['l', 'lo', 'lov', 'lo', '']) {
      await tester.enterText(find.byType(TextField), value);
      await tester.pump();
      expect(tester.widget<ClozeSentence>(find.byType(ClozeSentence)).input,
          value);
      if (value.isNotEmpty) {
        expect(
            find.descendant(
                of: find.byType(ClozeSentence), matching: find.text(value)),
            findsOneWidget);
      }
    }
    for (final value in ['wrong', 'again']) {
      await tester.enterText(find.byType(TextField), value);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(state.completed, 10);
      expect(state.learned, isEmpty);
      expect(state.reviews, isEmpty);
    }
    await tester.enterText(find.byType(TextField), 'love');
    await submitAnswer(tester);
    expect(state.completed, 11);
    expect(state.correctToday, 1);
    await tapText(tester, '학습 결과 보기');
    await tapText(tester, '단어 계속하기');
    expect(find.byType(TextField), findsOneWidget);
    expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text, '');
    expect(state.completed, 11);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Home and vocabulary start practice after the daily goal',
      (tester) async {
    phone(tester);
    final state = createLearning(completed: 10);
    await tester.pumpWidget(DailyEnglishApp(state: state));
    await tapText(tester, '단어 계속하기');
    expect(find.byType(WordPractice), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('home-shortcut-1')));
    await tester.pumpAndSettle();
    await tapText(tester, '단어 연습하기');
    expect(find.byType(WordPractice), findsOneWidget);
  });

  testWidgets(
      'Catalog filters spoken words, searches and starts a selected word',
      (tester) async {
    phone(tester);
    final state = createLearning();
    await tester.pumpWidget(MaterialApp(home: VocabularyCatalog(state: state)));
    expect(find.text('2897개'), findsOneWidget);
    await tester.tap(find.text('회화 핵심만'));
    await tester.pumpAndSettle();
    expect(find.text('721개'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'two');
    await tester.pumpAndSettle();
    expect(find.text('둘; 이'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '존재하지않는검색어');
    await tester.pumpAndSettle();
    expect(find.text('검색 결과가 없어요.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '여덟');
    await tester.pumpAndSettle();
    expect(find.text('eight'), findsOneWidget);
    await tester.tap(find.text('이 단어 연습하기'));
    await tester.pumpAndSettle();
    expect(find.byType(WordPractice), findsOneWidget);
    expect(find.text(wordsById['eight']!.translation), findsOneWidget);
    expect(tester.widget<ClozeSentence>(find.byType(ClozeSentence)).sentence,
        wordsById['eight']!.sentence);
    expect(find.byType(chat.DialogueTurn), findsNWidgets(2));
    expect(find.byKey(const ValueKey('dialogue-partner-translation')), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'eight');
    await submitAnswer(tester);
    expect(state.completed, 1);
    expect(state.correctToday, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Sentence cloze retries, translation and credits work on a narrow screen',
      (tester) async {
    phone(tester);
    tester.view.physicalSize = const Size(320, 700);
    final state = createLearning();
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
            data: const MediaQueryData(
                size: Size(320, 700), textScaler: TextScaler.linear(1.4)),
            child: WordPractice(
                state: state,
                exercises: [Exercise(wordsById['planet']!)],
                countsToday: true))));
    await tester.scrollUntilVisible(find.byType(TextField).first, 180,
        scrollable: find.byType(Scrollable).first);
    await tester.enterText(find.byType(TextField), 'pla');
    await tester.pump();
    // One text preview plus the editable field, with no answer leaked before reveal.
    expect(find.text('pla'), findsNWidgets(2));
    expect(
        tester.widget<ClozeSentence>(find.byType(ClozeSentence)).input, 'pla');
    expect(find.text(wordsById['planet']!.translation), findsOneWidget);
    expect(find.text('planet'), findsNothing);
    await submitAnswer(tester);
    expect(state.completed, 0);
    await tapText(tester, '정답 보기');
    expect(state.reviews.containsKey('planet'), isTrue);
    expect(state.completed, 1);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(state.completed, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Sources live in settings only, as plain text', (tester) async {
    phone(tester);
    final state = createLearning();
    await tester.pumpWidget(DailyEnglishApp(state: state));
    await tester.pumpAndSettle();
    expect(find.text(vocabularyCredits, skipOffstage: false), findsNothing);
    await tester.tap(find.byTooltip('학습 설정'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text(vocabularyCredits), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('자료 출처'), findsOneWidget);
    await tester.tap(find.text(vocabularyCredits));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Capture NGSL practice and attribution previews', (tester) async {
    phone(tester);
    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
        key: key,
        child: MaterialApp(
            theme: ThemeData(fontFamily: 'Preview', useMaterial3: true),
            home: WordPractice(
                state: createLearning(),
                exercises: [
                  Exercise(wordsById['water']!),
                  Exercise(wordsById['planet']!)
                ],
                countsToday: true))));
    await tester.pumpAndSettle();
    Future<void> capture(String name) async {
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory('build/previews').create(recursive: true);
        await File('build/previews/$name.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    await capture('ngsl-practice');
    // Sources live on the home screen; practice shows none.
    expect(find.textContaining('출처 및 이용조건'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Phrase filter opens exercise and captures continuous blank',
      (tester) async {
    phone(tester);
    final state = createLearning();
    await tester.pumpWidget(MaterialApp(home: VocabularyCatalog(state: state)));
    await tester.tap(find.text('숙어·구동사'));
    await tester.pumpAndSettle();
    expect(find.text('64개'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'look forward to');
    await tester.pumpAndSettle();
    await tester.tap(find.text('이 단어 연습하기'));
    await tester.pumpAndSettle();
    expect(find.byType(WordPractice), findsOneWidget);
    expect(find.text(wordsById['lookforwardto']!.translation), findsOneWidget);
    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
        key: key,
        child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(fontFamily: 'Preview', useMaterial3: true),
            home: WordPractice(
                state: state,
                exercises: [Exercise(wordsById['lookforwardto']!)],
                countsToday: true))));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('build/previews').create(recursive: true);
      await File('build/previews/phrase-practice.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
    expect(tester.takeException(), isNull);
  });
}
