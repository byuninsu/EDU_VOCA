import 'package:edu_voca/domain/models/review_entry.dart';
import 'package:edu_voca/domain/models/word_item.dart';

class Exercise {
  final WordItem word;
  final bool review;

  /// Miss history when the exercise was made; 0 misses means none recorded.
  final int misses;
  final DateTime? lastMissed;
  const Exercise(this.word,
      {this.review = false, this.misses = 0, this.lastMissed});

  /// A review of [entry], keeping its history as it was before this attempt.
  Exercise.fromReview(this.word, ReviewEntry entry)
      : review = true,
        misses = entry.misses,
        lastMissed = entry.lastMissed;

  /// Missed three or more times; reviewed sooner and marked on screen.
  bool get oftenMissed => misses >= 3;

  /// Short status for the practice header: new, revisit, or a missed review.
  String label(DateTime now) {
    if (!review) return '새로운 표현';
    if (misses == 0) return '다시 만나는 표현';
    final when = ReviewEntry(word.id, lastMissed: lastMissed).missedAgo(now);
    return misses >= 2 ? '복습 · $when 틀림 · $misses번 틀림' : '복습 · $when 틀림';
  }
}
