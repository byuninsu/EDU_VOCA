import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

/// Synthesized mono PCM ready for the native player.
class SpeechClip {
  final Float32List samples;
  final int sampleRate;
  const SpeechClip(this.samples, this.sampleRate);
}

/// On-device KittenTTS nano via sherpa-onnx. See assets/tts/NOTICE.md.
///
/// Synthesis runs in a background isolate so the UI never blocks. Recent
/// sentences stay in memory: the practice screen prepares the current
/// sentence while the learner types, and the answer popup plays it at once.
class KittenSpeechEngine {
  static const modelAssets = 'assets/tts/kitten_nano_v0_8';

  /// Speaker row in voices.bin (0–7). Change only after listening on a device.
  static const voice = 0;
  static const slowSpeed = 0.7;
  static const _cacheLimit = 12;
  static const _channel = MethodChannel('edu_voca/speech_audio');
  static final instance = KittenSpeechEngine._();
  KittenSpeechEngine._();

  Future<SendPort>? _worker;
  final _clips = <String, Future<SpeechClip>>{};

  Future<SpeechClip> synthesize(String text, {required bool slow}) {
    final key = '${slow ? 'slow' : 'normal'}|$text';
    final clip = _clips.remove(key) ?? _generate(text, slow ? slowSpeed : 1.0);
    _clips[key] = clip;
    if (_clips.length > _cacheLimit) _clips.remove(_clips.keys.first);
    clip.then((_) {}, onError: (Object _) {
      if (identical(_clips[key], clip)) _clips.remove(key);
    });
    return clip;
  }

  Future<void> play(SpeechClip clip) => _channel.invokeMethod('play',
      {'samples': clip.samples, 'sampleRate': clip.sampleRate});

  Future<void> stop() => _channel.invokeMethod('stop');

  Future<SpeechClip> _generate(String text, double speed) async {
    final worker = await (_worker ??= _start());
    final reply = ReceivePort();
    worker.send([text, speed, reply.sendPort]);
    final result = await reply.first;
    reply.close();
    if (result is! List) throw StateError('kitten-synthesis: $result');
    return SpeechClip(
        (result[0] as TransferableTypedData).materialize().asFloat32List(),
        result[1] as int);
  }

  Future<SendPort> _start() async {
    final dir = await _installModel();
    final ready = ReceivePort();
    await Isolate.spawn(_workerMain, [ready.sendPort, dir],
        debugName: 'kitten-tts');
    final first = await ready.first;
    ready.close();
    if (first is! SendPort) throw StateError('kitten-init: $first');
    return first;
  }

  /// The native engine needs real files, so bundled assets are copied once.
  Future<String> _installModel() async {
    final filesDir = await _channel.invokeMethod<String>('filesDir');
    final target = Directory('$filesDir/tts/${modelAssets.split('/').last}');
    final marker = File('${target.path}/.installed');
    if (await marker.exists()) return target.path;
    if (await target.exists()) await target.delete(recursive: true);
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    for (final asset in manifest.listAssets()) {
      if (!asset.startsWith('$modelAssets/')) continue;
      final data = await rootBundle.load(asset);
      final file = File('${target.path}/${asset.substring(modelAssets.length + 1)}');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          flush: true);
    }
    await marker.writeAsString('ok', flush: true);
    return target.path;
  }
}

void _workerMain(List<Object> args) {
  final ready = args[0] as SendPort;
  final dir = args[1] as String;
  final sherpa.OfflineTts tts;
  try {
    sherpa.initBindings();
    tts = sherpa.OfflineTts(sherpa.OfflineTtsConfig(
        model: sherpa.OfflineTtsModelConfig(
            kitten: sherpa.OfflineTtsKittenModelConfig(
                model: '$dir/model.int8.onnx',
                voices: '$dir/voices.bin',
                tokens: '$dir/tokens.txt',
                dataDir: '$dir/espeak-ng-data'),
            numThreads: 2,
            debug: false)));
  } catch (e) {
    ready.send('$e');
    return;
  }
  final requests = ReceivePort();
  ready.send(requests.sendPort);
  requests.listen((message) {
    final request = message as List;
    final reply = request[2] as SendPort;
    try {
      final audio = tts.generate(
          text: request[0] as String,
          sid: KittenSpeechEngine.voice,
          speed: request[1] as double);
      if (audio.samples.isEmpty) throw StateError('empty-audio');
      reply.send([
        TransferableTypedData.fromList([audio.samples]),
        audio.sampleRate
      ]);
    } catch (e) {
      reply.send('$e');
    }
  });
}
