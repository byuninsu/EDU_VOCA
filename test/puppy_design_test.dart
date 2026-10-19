import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edu_voca/app/app.dart';
import 'package:edu_voca/shared/widgets/ui.dart';
import 'package:edu_voca/features/learning/views/word_practice.dart';
import 'support.dart';

Future<void> prepare(WidgetTester tester, {double width = 390}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.runAsync(() async {
    final file = File('C:/Windows/Fonts/malgun.ttf');
    if (await file.exists()) {
      final loader = FontLoader('Preview');
      loader.addFont(file.readAsBytes().then(ByteData.sublistView));
      await loader.load();
    }
    final icons = FontLoader('MaterialIcons');
    icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
}

Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
  // Image codecs complete outside the test clock; wait for pixels, not just layout.
  for (var attempt = 0; attempt < 100; attempt++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump();
    if (tester
        .widgetList<RawImage>(find.byType(RawImage))
        .every((w) => w.image != null)) {
      break;
    }
  }
  expect(
      tester
          .widgetList<RawImage>(find.byType(RawImage))
          .every((w) => w.image != null),
      isTrue,
      reason: 'Mascot image pixels must be decoded before the preview');
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

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(find.text(text), 160,
      scrollable: find.byType(Scrollable).first);
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

void main() {
  test('Launcher uses unchanged supplied PNG and legacy/adaptive resources',
      () {
    expect(
        File('android/app/src/main/res/drawable-nodpi/puppy_character.png')
            .readAsBytesSync(),
        orderedEquals(File('images/main_Character.png').readAsBytesSync()));
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest, contains('android:icon="@mipmap/puppy_launcher"'));
    expect(
        File('android/app/src/main/res/mipmap-anydpi/puppy_launcher.xml')
            .existsSync(),
        isTrue);
    expect(
        File('android/app/src/main/res/mipmap-anydpi-v26/puppy_launcher.xml')
            .readAsStringSync(),
        contains('<adaptive-icon'));
  });

  testWidgets(
      'Home renders supplied mascot, warm theme and visible start action',
      (tester) async {
    await prepare(tester);
    final key = GlobalKey();
    final state = createLearning();
    await tester.pumpWidget(RepaintBoundary(
        key: key, child: DailyEnglishApp(state: state, fontFamily: 'Preview')));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pumpAndSettle();
    expect(find.byType(PuppyMascot), findsAtLeastNWidgets(2));
    expect(find.text('오늘의 학습 시작').hitTestable(), findsOneWidget);
    expect(
        Theme.of(tester.element(find.byType(PuppyMascot).first))
            .scaffoldBackgroundColor,
        paper);
    expect(tester.takeException(), isNull);
    await capture(tester, key, 'puppy-home');
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });

  testWidgets('Narrow large-text home and tabs do not overflow',
      (tester) async {
    await prepare(tester, width: 320);
    final state = createLearning();
    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
        key: key,
        child: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: DailyEnglishApp(state: state, fontFamily: 'Preview'))));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    for (final i in [1, 2, 3]) {
      await tester.ensureVisible(find.byKey(ValueKey('home-shortcut-$i')));
      await tester.tap(find.byKey(ValueKey('home-shortcut-$i')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      if (i < 3) {
        await tester.tap(find.byKey(const ValueKey('section-back')));
        await tester.pumpAndSettle();
      }
    }
    expect(find.text('아직 쌓인 복습이 없어요'), findsOneWidget);
    await capture(tester, key, 'puppy-review');
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });

  testWidgets(
      'Practice uses puppy styling while live input and hints still work',
      (tester) async {
    await prepare(tester);
    final state = createLearning();
    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
        key: key, child: DailyEnglishApp(state: state, fontFamily: 'Preview')));
    final context = tester.element(find.byType(PuppyMascot).first);
    Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => WordPractice(
            state: state,
            exercises: [Exercise(wordsById['water']!)],
            countsToday: true)));
    await tester.pumpAndSettle();
    await capture(tester, key, 'puppy-practice');
    await tester.enterText(find.byType(TextField), 'wa');
    expect(find.text('wa'), findsWidgets);
    await tapText(tester, '힌트 보기');
    expect(find.text("'w'로 시작하는 표현이에요."), findsOneWidget);
    expect(find.text('wa'), findsWidgets);
    await tester.enterText(find.byType(TextField), 'water');
    await submitAnswer(tester);
    expect(state.correctToday, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await state.flush();
    state.dispose();
  });

  testWidgets('Completed practice shows mascot and can continue',
      (tester) async {
    await prepare(tester);
    final state = createLearning();
    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
        key: key, child: DailyEnglishApp(state: state, fontFamily: 'Preview')));
    Navigator.of(tester.element(find.byType(PuppyMascot).first)).push(
        MaterialPageRoute<void>(
            builder: (_) => WordPractice(
                state: state,
                exercises: [Exercise(wordsById['love']!)],
                countsToday: true)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'love');
    await submitAnswer(tester);
    await tapText(tester, '학습 결과 보기');
    expect(find.text('한 걸음 더 가까워졌어요!'), findsOneWidget);
    await capture(tester, key, 'puppy-complete');
    await tapText(tester, '단어 계속하기');
    expect(find.byType(TextField), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await state.flush();
    state.dispose();
  });
}
