import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../data/services/sentence_speech_service.dart';

class SentenceSpeechViewModel extends ChangeNotifier {
  final SentenceSpeechService service;
  bool _disposed = false;
  int _revision = 0;
  String? message;
  SentenceSpeechViewModel({SentenceSpeechService? service})
      : service = service ?? SentenceSpeechService() {
    this.service.onError = _showError;
  }

  void _showError() {
    if (_disposed) return;
    message = '음성을 재생하지 못했어요.\n휴대폰의 텍스트 읽어주기 설정에서 영어 음성을 확인해 주세요.';
    notifyListeners();
  }

  void prepare(String sentence) {
    if (!_disposed) service.prepare(sentence);
  }

  Future<void> speak(String sentence, {bool slow = false}) async {
    if (_disposed) return;
    final revision = ++_revision;
    message = null;
    notifyListeners();
    try {
      await service.speak(sentence, slow: slow);
    } catch (_) {
      if (_disposed || revision != _revision) return;
      _showError();
    }
  }

  Future<void> stop() async {
    ++_revision;
    try {
      await service.stop();
    } catch (_) {/* Closing must remain possible. */}
  }

  @override
  void dispose() {
    _disposed = true;
    service.onError = null;
    unawaited(stop());
    super.dispose();
  }
}
