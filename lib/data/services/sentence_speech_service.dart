import 'dart:async';
import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';
import 'kitten_speech_engine.dart';

/// Serializes engine commands; a closed popup must never start delayed speech.
/// Android uses the bundled Kitten voice; if it cannot start, the phone's
/// text-to-speech engine is used for the rest of the session.
class SentenceSpeechService {
  SentenceSpeechService({KittenSpeechEngine? neural})
      : _neural =
            neural ?? (Platform.isAndroid ? KittenSpeechEngine.instance : null);
  KittenSpeechEngine? _neural;
  FlutterTts? _engine;
  Future<void> _queue = Future.value();
  int _revision = 0;
  bool _ready = false;
  void Function()? onError;

  /// Synthesizes ahead of time so a later [speak] can start immediately.
  void prepare(String text) => _neural?.synthesize(text, slow: false).ignore();

  Future<void> speak(String text, {required bool slow}) async {
    final revision = ++_revision;
    final neural = _neural;
    if (neural != null) {
      _enqueue(neural.stop).ignore();
      try {
        final clip = await neural.synthesize(text, slow: slow);
        if (revision != _revision) return;
        return await _enqueue(() async {
          if (revision == _revision) await neural.play(clip);
        });
      } catch (_) {
        if (identical(_neural, neural)) _neural = null;
        if (revision != _revision) return;
      }
    }
    return _enqueue(() async {
      if (revision != _revision) return;
      final engine = _engine ??= FlutterTts();
      engine.setErrorHandler((_) {
        if (revision == _revision) onError?.call();
      });
      await engine.stop();
      if (!_ready) {
        final available = await engine.isLanguageAvailable('en-US');
        if (available != true && available != 1) {
          throw StateError('english-unavailable');
        }
        if (await engine.setLanguage('en-US') != 1) {
          throw StateError('english-unavailable');
        }
        await engine.awaitSpeakCompletion(false);
        await engine.setVolume(1.0);
        await engine.setPitch(1.0);
        _ready = true;
      }
      if (revision != _revision) return;
      await engine.setSpeechRate(slow ? 0.3 : 0.5);
      if (revision != _revision) return;
      if (await engine.speak(text, focus: true) != 1) {
        throw StateError('speech-failed');
      }
    });
  }

  Future<void> stop() {
    ++_revision;
    final neural = _neural;
    return _enqueue(() async {
      await _engine?.stop();
      await neural?.stop();
    });
  }

  Future<void> _enqueue(Future<void> Function() action) {
    final result = _queue.then((_) => action());
    _queue = result.catchError((Object _) {});
    return result;
  }
}
