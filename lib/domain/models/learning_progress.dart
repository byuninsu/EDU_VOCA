import 'package:edu_voca/domain/models/review_entry.dart';

/// What one answer did to the experience bar.
class XpResult {
  /// +1 for a new correct word, -[LearningProgress.missPenalty] for a miss,
  /// 0 when the word is outside the current difficulty or already counted.
  final int gained;

  /// +1 level up, -1 level down, 0 unchanged.
  final int levelChange;
  const XpResult(this.gained, this.levelChange);
  static const none = XpResult(0, 0);
}

class LearningProgress {
  int dailyGoal = 10, completed = 0, correctToday = 0;
  String day = dateKey(DateTime.now());
  final Set<String> learned = {};
  int get learnedCount => learned.length;
  int level = 1;
  static const maxLevel = 20, missPenalty = 2;

  /// Experience toward the next level; [xpWords] already earned it here.
  int xp = 0;
  final Set<String> xpWords = {};

  /// Experience for the next level: 5 at Lv. 1 rising to 20 at Lv. 19, so
  /// low levels move (both ways) quickly and high levels slowly.
  static int xpNeeded(int level) =>
      level >= maxLevel ? 0 : 5 + ((level - 1) * 15 / 18).round();
  int get xpToNext => xpNeeded(level);
  static int starsOf(int level) => (level - 1) ~/ 4 + 1;
  static String cefrOf(int level) =>
      const ['A1', 'A2', 'B1', 'B2', 'C1'][starsOf(level) - 1];
  int get targetStars => starsOf(level);
  String get targetCefr => cefrOf(level);
  final Set<String> seen = {};
  final Map<String, ReviewEntry> reviews = {};
  final Map<String, String> writingReviews = {};
  static String dateKey(DateTime date) =>
      '${date.year}-${date.month}-${date.day}';
  void restore(Map<String, dynamic> d, Set<String> vocabularyIds,
      Set<String> wordsById) {
    dailyGoal = (d['goal'] as int).clamp(5, 30);
    level = ((d['adaptiveLevel20'] as int?) ?? 1).clamp(1, 20);
    // Older records kept a streak of up to 2 words: count each as experience.
    final words =
        ((d['xpWords'] ?? d['levelStreak']) as List? ?? []).cast<String>();
    xpWords.addAll(words);
    final need = xpToNext;
    xp = need == 0 ? 0 : ((d['xp'] as int?) ?? words.length).clamp(0, need - 1);
    day = d['day'] as String;
    completed = d['completed'] as int;
    correctToday = d['correct'] as int;
    seen.addAll((d['seen'] as List).cast<String>());
    for (final item in d['reviews'] as List) {
      final entry =
          ReviewEntry.fromJson(Map<String, dynamic>.from(item as Map));
      if (wordsById.contains(entry.id)) {
        reviews[entry.id] = entry;
      }
    }
    writingReviews.addAll(Map<String, String>.from(d['writing'] as Map));
    final savedLearned = d['learned'] as List?;
    if (savedLearned != null) {
      learned.addAll(savedLearned.cast<String>().where(vocabularyIds.contains));
    } else {
      // Old records: a seen word without a failed review, or with a successful
      // review stage, has a recorded correct final answer. Never infer from level.
      learned.addAll(seen.where((id) =>
          vocabularyIds.contains(id) &&
          (!reviews.containsKey(id) || reviews[id]!.stage > 0)));
    }
  }

  Map<String, dynamic> toJson() => {
        'goal': dailyGoal,
        'level': level,
        'adaptiveLevel20': level,
        'xp': xp,
        'xpWords': xpWords.toList(),
        'day': day,
        'completed': completed,
        'correct': correctToday,
        'learned': learned.toList(),
        'seen': seen.toList(),
        'reviews': reviews.values.map((r) => r.toJson()).toList(),
        'writing': writingReviews,
      };
}
