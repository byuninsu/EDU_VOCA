import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:edu_voca/domain/models/scenario.dart';
import 'package:edu_voca/domain/models/exercise.dart';
import 'package:edu_voca/domain/models/review_entry.dart';
import 'package:edu_voca/domain/models/learning_progress.dart';
import 'package:edu_voca/domain/repositories/vocabulary_repository.dart';
import 'package:edu_voca/domain/repositories/progress_repository.dart';
import 'package:edu_voca/domain/services/learning_service.dart';

class LearningViewModel extends ChangeNotifier {
  final ProgressRepository repository;
  final VocabularyRepository vocabulary;
  final LearningProgress _progress = LearningProgress();
  late final LearningService _service = LearningService(_progress, vocabulary);
  String? storageError;
  bool _disposed = false;
  Future<void> _saveQueue = Future.value();
  LearningViewModel({required this.repository, required this.vocabulary}) {
    try {
      final data = repository.load();
      if (data != null) {
        _progress.restore(data, vocabulary.words.map((w) => w.id).toSet(),
            vocabulary.byId.keys.toSet());
      }
      _service.refreshDay();
    } catch (_) {
      storageError = '저장된 기록 일부를 읽지 못했어요.\n설정과 복습 목록을 확인해 주세요.';
    }
  }
  static String dateKey(DateTime date) => LearningProgress.dateKey(date);
  int get dailyGoal => _progress.dailyGoal;
  int get completed => _progress.completed;
  int get correctToday => _progress.correctToday;
  int get level => _progress.level;
  int get learnedCount => _progress.learnedCount;
  int get targetStars => _progress.targetStars;
  String get targetCefr => _progress.targetCefr;
  int get xp => _progress.xp;
  int get xpToNext => _progress.xpToNext;
  String get day => _progress.day;
  Set<String> get learned => Set.unmodifiable(_progress.learned);
  Set<String> get seen => Set.unmodifiable(_progress.seen);
  Map<String, ReviewEntry> get reviews => Map.unmodifiable(_progress.reviews);
  Map<String, String> get writingReviews =>
      Map.unmodifiable(_progress.writingReviews);
  int get dueCount => _service.dueCount;
  void refreshDay() {
    final previous = day;
    _service.refreshDay();
    if (previous != day) _changed();
  }

  List<Exercise> makeSession() {
    refreshDay();
    return _service.makeSession();
  }

  void settings(int goal, {int? startingLevel}) {
    _service.settings(goal, startingLevel: startingLevel);
    _changed();
  }

  XpResult answer(Exercise exercise, bool correct,
      {required bool countsToday}) {
    final result = _service.answer(exercise, correct, countsToday: countsToday);
    _changed();
    return result;
  }

  void saveWriting(Scenario scenario, String answer) {
    _service.saveWriting(scenario, answer);
    _changed();
  }

  void finishWriting(String id) {
    _service.finishWriting(id);
    _changed();
  }

  Future<void> flush() => _saveQueue;
  void _changed() {
    // Freeze now so queued writes cannot observe later mutations.
    final snapshot =
        jsonDecode(jsonEncode(_progress.toJson())) as Map<String, dynamic>;
    _saveQueue = _saveQueue.then((_) async {
      try {
        await repository.save(snapshot);
      } catch (_) {
        storageError = '기록을 저장하지 못했어요.\n앱을 종료하면 최근 기록이 사라질 수 있어요.';
        if (!_disposed) notifyListeners();
      }
    });
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
