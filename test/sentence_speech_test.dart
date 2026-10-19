import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edu_voca/data/services/sentence_speech_service.dart';
import 'package:edu_voca/features/learning/views/word_practice.dart';
import 'support.dart';
import 'puppy_design_test.dart' show prepare, tapText;

const channel = MethodChannel('flutter_tts');
final calls = <MethodCall>[];
bool available = true;
Completer<void>? gate;

Future<void> open(WidgetTester tester) async {
  await prepare(tester);
  final state = createLearning();
  addTearDown(state.dispose);
  await tester.pumpWidget(MaterialApp(
      home: WordPractice(
          state: state,
          exercises: [
            Exercise(wordsById['atfirst']!),
            Exercise(wordsById['water']!)
          ],
          countsToday: true)));
  await tapText(tester, '정답 보기');
}

void main() {
  setUp(() {
    calls.clear();
    available = true;
    gate = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'isLanguageAvailable') {
        if (gate != null) await gate!.future;
        return available;
      }
      return 1;
    });
  });
  tearDown(() => TestDefaultBinaryMessengerBinding
      .instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, null));

  testWidgets(
      'Popup reads completed phrase exactly once; rebuild does not replay',
      (tester) async {
    await open(tester);
    final spoken = calls.where((c) => c.method == 'speak').toList();
    expect(spoken.length, 1);
    final argument = spoken.single.arguments;
    expect(argument is Map ? argument['text'] : argument,
        wordsById['atfirst']!.complete);
    await tester.pump();
    expect(calls.where((c) => c.method == 'speak').length, 1);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
  testWidgets('Both buttons replay and slow speed resets on normal replay',
      (tester) async {
    await open(tester);
    for (final label in ['천천히 듣기', '문장 듣기']) {
      await tester.ensureVisible(find.text(label));
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }
    expect(
        calls.where((c) => c.method == 'setSpeechRate').map((c) => c.arguments),
        [0.5, 0.3, 0.5]);
    expect(calls.where((c) => c.method == 'speak').length, 3);
    expect(
        calls.where((c) => c.method == 'stop').length, greaterThanOrEqualTo(3));
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
  testWidgets('Closing, next and app background stop speech', (tester) async {
    await open(tester);
    calls.clear();
    await tester.tap(find.byTooltip('닫기'));
    await tester.pumpAndSettle();
    expect(calls.any((c) => c.method == 'stop'), isTrue);
    await tapText(tester, '해설 다시 보기');
    calls.clear();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(calls.any((c) => c.method == 'stop'), isTrue);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    calls.clear();
    await tester.tap(
        find.descendant(of: find.byType(Dialog), matching: find.text('확인')));
    await tester.pumpAndSettle();
    expect(calls.any((c) => c.method == 'stop'), isTrue);
    expect(calls.any((c) => c.method == 'speak'), isFalse);
    expect(find.text('2 / 2'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
  testWidgets('Closing during engine preparation prevents late speech',
      (tester) async {
    gate = Completer<void>();
    final service = SentenceSpeechService();
    final pending = service.speak('This must not play.', slow: false);
    await tester.pump();
    final stopped = service.stop();
    gate!.complete();
    await tester.pump();
    await pending;
    await stopped;
    expect(calls.any((c) => c.method == 'speak'), isFalse);
  });
  testWidgets('Missing English voice shows guidance and retry works',
      (tester) async {
    available = false;
    await open(tester);
    expect(find.textContaining('영어 음성을 확인'), findsOneWidget);
    expect(calls.any((c) => c.method == 'speak'), isFalse);
    available = true;
    await tester.ensureVisible(find.text('문장 듣기'));
    await tester.tap(find.text('문장 듣기'));
    await tester.pumpAndSettle();
    expect(calls.where((c) => c.method == 'speak').length, 1);
    expect(find.textContaining('영어 음성을 확인'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
