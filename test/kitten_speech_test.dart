import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edu_voca/data/services/kitten_speech_engine.dart';
import 'package:edu_voca/data/services/sentence_speech_service.dart';

class FakeKitten implements KittenSpeechEngine {
  final synthesized = <String>[];
  final played = <SpeechClip>[];
  int stops = 0;
  bool fail = false;
  Completer<void>? gate;

  @override
  Future<SpeechClip> synthesize(String text, {required bool slow}) async {
    synthesized.add('${slow ? 'slow' : 'normal'}:$text');
    if (gate != null) await gate!.future;
    if (fail) throw StateError('kitten-init');
    return SpeechClip(Float32List(4), 24000);
  }

  @override
  Future<void> play(SpeechClip clip) async => played.add(clip);

  @override
  Future<void> stop() async => stops++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter_tts');
  final ttsCalls = <MethodCall>[];
  setUp(() {
    ttsCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      ttsCalls.add(call);
      return call.method == 'isLanguageAvailable' ? true : 1;
    });
  });
  tearDown(() => TestDefaultBinaryMessengerBinding
      .instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, null));

  test('Kitten voice plays normal and slow clips without phone TTS', () async {
    final kitten = FakeKitten();
    final service = SentenceSpeechService(neural: kitten);
    service.prepare('Can I have some water?');
    await service.speak('Can I have some water?', slow: false);
    await service.speak('Can I have some water?', slow: true);
    expect(kitten.synthesized, [
      'normal:Can I have some water?',
      'normal:Can I have some water?',
      'slow:Can I have some water?'
    ]);
    expect(kitten.played.length, 2);
    expect(kitten.stops, 2);
    expect(ttsCalls, isEmpty);
  });

  test('Stopping during Kitten synthesis prevents late playback', () async {
    final kitten = FakeKitten()..gate = Completer<void>();
    final service = SentenceSpeechService(neural: kitten);
    final pending = service.speak('This must not play.', slow: false);
    await Future<void>.delayed(Duration.zero);
    await service.stop();
    kitten.gate!.complete();
    await pending;
    expect(kitten.played, isEmpty);
    expect(kitten.stops, greaterThanOrEqualTo(2));
    expect(ttsCalls.where((c) => c.method == 'speak'), isEmpty);
  });

  test('Kitten failure falls back to phone TTS for the session', () async {
    final kitten = FakeKitten()..fail = true;
    final service = SentenceSpeechService(neural: kitten);
    service.prepare('Are you ready to order?');
    await service.speak('Are you ready to order?', slow: false);
    await service.speak('Are you ready to order?', slow: true);
    expect(kitten.synthesized.length, 2);
    expect(kitten.played, isEmpty);
    expect(ttsCalls.where((c) => c.method == 'speak').length, 2);
    expect(
        ttsCalls.where((c) => c.method == 'setSpeechRate').map((c) => c.arguments),
        [0.5, 0.3]);
  });
}
