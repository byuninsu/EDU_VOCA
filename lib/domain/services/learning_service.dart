import 'dart:math';

import 'package:edu_voca/domain/models/word_item.dart';
import 'package:edu_voca/domain/models/scenario.dart';
import 'package:edu_voca/domain/models/exercise.dart';
import 'package:edu_voca/domain/models/review_entry.dart';
import 'package:edu_voca/domain/models/learning_progress.dart';
import 'package:edu_voca/domain/repositories/vocabulary_repository.dart';

class LearningService {
  final LearningProgress progress;
  final VocabularyRepository vocabulary;
  final Random _random;
  LearningService(this.progress, this.vocabulary, {Random? random})
      : _random = random ?? Random();
  void refreshDay() {
    final today = LearningProgress.dateKey(DateTime.now());
    if (progress.day == today) return;
    progress.day = today;
    progress.completed = 0;
    progress.correctToday = 0;
  }

  void settings(int goal, {int? startingLevel}) {
    progress.dailyGoal = goal.clamp(5, 30);
    if (startingLevel != null) {
      progress.level = startingLevel.clamp(1, LearningProgress.maxLevel);
      progress.xp = 0;
      progress.xpWords.clear();
    }
  }

  int get dueCount => progress.reviews.values
      .where((r) => !r.due.isAfter(DateTime.now()))
      .length;
  List<Exercise> makeSession() {
    refreshDay();
    final remaining = progress.completed >= progress.dailyGoal
        ? progress.dailyGoal
        : progress.dailyGoal - progress.completed;
    // Up to 40% due reviews, most often missed first, then longest overdue.
    final due = progress.reviews.values
        .where((r) => !r.due.isAfter(DateTime.now()))
        .toList()
      ..sort((a, b) {
        final misses = b.misses.compareTo(a.misses);
        return misses != 0 ? misses : a.due.compareTo(b.due);
      });
    final selected = <Exercise>[];
    for (final r in due.take((remaining * .4).ceil())) {
      selected.add(Exercise.fromReview(vocabulary.byId[r.id]!, r));
    }
    final recency = {
      for (final (index, id) in progress.seen.indexed) id: index
    };
    // Give unseen words a fresh random priority on every session, including
    // when the previous session was closed before answering a question.
    final randomOrder = vocabulary.words.toList()..shuffle(_random);
    final randomRank = {
      for (final (index, word) in randomOrder.indexed) word.id: index
    };
    final candidates = vocabulary.words
        .where((w) => !selected.any((e) => e.word.id == w.id))
        .toList()
      ..sort((a, b) {
        final seenCompare = (progress.seen.contains(a.id) ? 1 : 0)
            .compareTo(progress.seen.contains(b.id) ? 1 : 0);
        if (seenCompare != 0) return seenCompare;
        if (progress.seen.contains(a.id) && progress.seen.contains(b.id)) {
          return recency[a.id]!.compareTo(recency[b.id]!);
        }
        return randomRank[a.id]!.compareTo(randomRank[b.id]!);
      });
    // Grammar words are met mostly inside phrases; single words favor verbs,
    // adjectives and adverbs. Unseen words are randomized within each group.
    final functionLimit = remaining ~/ 10;
    final nounLimit = (remaining * .3).ceil();
    bool fits(WordItem w) {
      if (w.isFunctionWord) {
        return selected.where((e) => e.word.isFunctionWord).length <
            functionLimit;
      }
      if (w.isNounLike) {
        return selected.where((e) => e.word.isNounLike).length < nounLimit;
      }
      return true;
    }

    void takeWords(Iterable<WordItem> pool, int count, {bool any = false}) {
      var added = 0;
      for (final w in pool) {
        if (added >= count) break;
        if (selected.any((e) => e.word.id == w.id) || !(any || fits(w))) {
          continue;
        }
        final entry = progress.reviews[w.id];
        selected.add(entry != null
            ? Exercise.fromReview(w, entry)
            : Exercise(w, review: progress.seen.contains(w.id)));
        added++;
      }
    }

    // About 20% expressions without inventing their CEFR.
    if (remaining >= 5) {
      takeWords(candidates.where((w) => w.isPhrase),
          remaining ~/ 5 - selected.where((e) => e.word.isPhrase).length);
    }
    // About 70% target difficulty; remaining slots revisit easier basics.
    takeWords(
        candidates.where((w) => w.difficultyStars == progress.targetStars),
        (remaining * .7).ceil().clamp(0, remaining - selected.length));
    if (remaining >= 15 && selected.length < remaining) {
      takeWords(
          candidates.where((w) =>
              !w.isPhrase &&
              w.difficultyStars == null &&
              !progress.seen.contains(w.id)),
          1);
    }
    takeWords(
        candidates.where((w) =>
            w.difficultyStars != null &&
            w.difficultyStars! < progress.targetStars),
        remaining - selected.length);
    takeWords(
        candidates.where((w) => w.difficultyStars == progress.targetStars),
        remaining - selected.length);
    takeWords(candidates, remaining - selected.length);
    takeWords(candidates, remaining - selected.length, any: true);
    final fresh = selected.where((e) => !e.review).toList()..shuffle(_random);
    return spread([...fresh, ...selected.where((e) => e.review)]);
  }

  /// Spreads reviews evenly between new questions, starting with a new one
  /// when there is one (10 questions with 4 reviews: N N R N R N R N R N).
  static List<Exercise> spread(List<Exercise> exercises) {
    final reviews = exercises.where((e) => e.review).toList();
    final fresh = exercises.where((e) => !e.review).toList();
    final slots = {
      for (var k = 0; k < reviews.length; k++)
        (k + 1) * exercises.length ~/ (reviews.length + 1)
    };
    return [
      for (var i = 0; i < exercises.length; i++)
        (slots.contains(i) && reviews.isNotEmpty) || fresh.isEmpty
            ? reviews.removeAt(0)
            : fresh.removeAt(0)
    ];
  }

  /// Days until the next review after a correct answer. Each miss beyond the
  /// first shortens the wait (2 misses: x2/3, 3 misses: x1/2), at least a day.
  static Duration interval(int stage, int misses) {
    const days = [1, 3, 7, 14, 30];
    final hours = days[stage.clamp(0, 4)] * 24 / (1 + .5 * (misses - 1));
    return Duration(hours: hours.round().clamp(24, 30 * 24));
  }

  /// Only words of the current difficulty move the bar. A correct word earns
  /// 1 once per level; a miss costs [LearningProgress.missPenalty], and going
  /// below zero drops a level with the remainder taken from its full bar.
  XpResult _experience(WordItem word, bool correct) {
    final p = progress;
    if (word.difficultyStars != p.targetStars) return XpResult.none;
    if (correct) {
      if (p.level >= LearningProgress.maxLevel || !p.xpWords.add(word.id)) {
        return XpResult.none;
      }
      if (++p.xp < p.xpToNext) return const XpResult(1, 0);
      p.level++;
      p.xp = 0;
      p.xpWords.clear();
      return const XpResult(1, 1);
    }
    p.xp -= LearningProgress.missPenalty;
    if (p.xp >= 0) return const XpResult(-LearningProgress.missPenalty, 0);
    if (p.level == 1) {
      final lost = LearningProgress.missPenalty + p.xp;
      p.xp = 0;
      return XpResult(-lost, 0);
    }
    p.level--;
    p.xp = (p.xpToNext + p.xp).clamp(0, p.xpToNext - 1);
    p.xpWords.clear();
    return const XpResult(-LearningProgress.missPenalty, -1);
  }

  XpResult answer(Exercise exercise, bool correct,
      {required bool countsToday}) {
    refreshDay();
    final word = exercise.word;
    final xp = _experience(word, correct);
    if (countsToday) {
      progress.completed++;
      if (correct) progress.correctToday++;
    }
    if (vocabulary.words.any((w) => w.id == word.id)) {
      if (correct) {
        progress.learned.add(word.id);
      } else {
        progress.learned.remove(word.id);
      }
    }
    progress.seen.remove(word.id);
    progress.seen.add(word.id);
    final now = DateTime.now();
    final review = progress.reviews[word.id];
    if (!correct) {
      // Missed again: back to the first step, due right away, one more miss.
      progress.reviews[word.id] = ReviewEntry(word.id,
          due: now, misses: (review?.misses ?? 0) + 1, lastMissed: now);
    } else if (review != null) {
      review.due = now.add(interval(review.stage, review.misses));
      review.stage = (review.stage + 1).clamp(0, 4);
    }
    return xp;
  }

  void saveWriting(Scenario scenario, String answer) {
    progress.writingReviews[scenario.id] = answer.trim();
  }

  void finishWriting(String id) {
    progress.writingReviews.remove(id);
  }
}
