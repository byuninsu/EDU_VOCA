import 'package:flutter_test/flutter_test.dart';
import 'package:edu_voca/domain/models/learning_progress.dart';
import 'package:edu_voca/domain/models/review_entry.dart';
import 'package:edu_voca/domain/services/learning_service.dart';
import 'support.dart';

void main() {
  test('Experience counts distinct correct words, not repeated answers', () {
    final state = createLearning();
    final a1 = playableWords.where((w) => w.difficultyStars == 1).toList();
    for (final w in a1.take(4)) {
      expect(state.answer(Exercise(w), true, countsToday: false).gained, 1);
    }
    expect((state.level, state.xp, state.xpToNext), (1, 4, 5));
    // The same word again earns nothing.
    expect(state.answer(Exercise(a1[0]), true, countsToday: false).gained, 0);
    final up = state.answer(Exercise(a1[4]), true, countsToday: false);
    expect((up.gained, up.levelChange), (1, 1));
    expect((state.level, state.xp, state.xpToNext), (2, 0, 6));
    expect(state.learnedCount, 5);
  });

  test('Bars grow with level: quick at the bottom, slow at the top', () {
    expect([for (var l = 1; l <= 20; l++) LearningProgress.xpNeeded(l)],
        [5, 6, 7, 8, 8, 9, 10, 11, 12, 13, 13, 14, 15, 16, 17, 18, 18, 19, 20, 0]);
  });

  test('A miss costs 2 and below zero drops a level near its top', () {
    final state = createLearning()..settings(10, startingLevel: 2);
    final a1 = playableWords.firstWhere((w) => w.difficultyStars == 1);
    final down = state.answer(Exercise(a1), false, countsToday: false);
    expect((down.gained, down.levelChange), (-2, -1));
    expect((state.level, state.xp), (1, 3)); // 5 - 2
    state.answer(Exercise(a1), false, countsToday: false);
    expect((state.level, state.xp), (1, 1));
    final floor = state.answer(Exercise(a1), false, countsToday: false);
    expect((floor.gained, state.level, state.xp), (-1, 1, 0));
  });
  test('Frequent errors reduce the level and preserve bounds', () {
    final state = createLearning();
    state.settings(10);
    for (final w in playableWords.take(20)) {
      state.answer(Exercise(w), false, countsToday: false);
    }
    expect(state.level, 1);
    expect(state.reviews.length, 20);
  });
  test('Review moves to future and starts a correct streak', () {
    final state = createLearning();
    final word = playableWords.first;
    state.answer(Exercise(word), false, countsToday: true);
    expect(state.dueCount, 1);
    state.answer(Exercise(word, review: true), true, countsToday: false);
    expect(state.dueCount, 0);
    expect(state.learned, contains(word.id));
    expect(state.completed, 1);
  });
  test('Daily session honors remaining goal and includes due errors', () {
    final state = createLearning();
    state.answer(Exercise(playableWords.first), false, countsToday: true);
    final session = state.makeSession();
    expect(session.length, 9);
    expect(session.any((e) => e.word.id == playableWords.first.id && e.review),
        isTrue);
    expect(session.map((e) => e.word.id).toSet().length, session.length);
  });
  test('Sessions favor phrases and content words over grammar words', () {
    for (final level in [1, 5, 9]) {
      final state = createLearning()..settings(10, startingLevel: level);
      for (var round = 0; round < 5; round++) {
        final session = state.makeSession();
        expect(session, hasLength(10));
        expect(session.where((e) => e.word.isPhrase), hasLength(2));
        expect(session.where((e) => e.word.isFunctionWord).length,
            lessThanOrEqualTo(1));
        expect(session.where((e) => e.word.isNounLike).length,
            lessThanOrEqualTo(3));
        for (final e in session) {
          state.answer(e, true, countsToday: true);
        }
      }
    }
    expect(wordsById['the']!.isFunctionWord, isTrue);
    expect(wordsById['of']!.isFunctionWord, isTrue);
    expect(wordsById['like']!.isFunctionWord, isFalse);
    expect(wordsById['know']!.isNounLike, isFalse);
  });
  test('Target difficulty controls adaptive level and bounds', () {
    final state = createLearning();
    state.settings(10, startingLevel: 8);
    final a2 =
        playableWords.where((w) => w.difficultyStars == 2).take(11).toList();
    for (final w in a2) {
      state.answer(Exercise(w), true, countsToday: false);
    }
    expect(state.level, 9);
    expect(state.targetCefr, 'B1');
    // Easier words no longer move the bar.
    for (final w in a2) {
      expect(state.answer(Exercise(w), true, countsToday: false).gained, 0);
    }
    expect((state.level, state.xp), (9, 0));
    final b1 = playableWords.firstWhere((w) => w.difficultyStars == 3);
    state.answer(Exercise(b1), false, countsToday: false);
    expect((state.level, state.xp), (8, 9)); // 11 - 2
    state.settings(10, startingLevel: 20);
    for (final w
        in playableWords.where((w) => w.difficultyStars == 5).take(3)) {
      state.answer(Exercise(w), true, countsToday: false);
    }
    expect((state.level, state.xpToNext), (20, 0));
  });
  test('Practice continues beyond goal and cycles through seen words', () {
    final state = createLearning()..settings(5);
    final first = state.makeSession();
    for (final exercise in first) {
      state.answer(exercise, true, countsToday: true);
    }
    final second = state.makeSession();
    expect(second.length, 5);
    expect(
        second.every((e) => !first.any((f) => f.word.id == e.word.id)), isTrue);
    for (var round = 0; round < 10; round++) {
      for (final exercise in state.makeSession()) {
        state.answer(exercise, true, countsToday: true);
      }
    }
    expect(state.completed, 55);
    expect(state.seen.length, 55);

    final repeat = state.makeSession();
    for (final e in repeat) {
      state.answer(e, true, countsToday: true);
    }
    expect(
        state
            .makeSession()
            .every((e) => !repeat.any((r) => r.word.id == e.word.id)),
        isTrue);
    expect(state.makeSession(), hasLength(5));
  });
  test('Date rollover resets today only', () async {
    final state = createLearning();
    state.answer(Exercise(playableWords.first), false, countsToday: true);
    await state.flush();
    final snapshot = state.repository.load()!;
    snapshot['day'] = '2000-1-1';
    await state.repository.save(snapshot);
    final restored =
        LearningViewModel(repository: state.repository, vocabulary: vocabulary);
    restored.refreshDay();
    expect(restored.completed, 0);
    expect(restored.reviews.length, 1);
  });
  test('Alternative answers and whitespace are accepted', () {
    final check = playableWords.firstWhere((w) => w.id == 'check');
    expect(check.accepts(' BILL! '), isTrue);
    expect(check.accepts(''), isFalse);
  });

  test('Misses accumulate, shorten the next wait, and come first', () {
    final state = createLearning();
    final often = playableWords[0], once = playableWords[1];
    state.answer(Exercise(once), false, countsToday: false);
    for (var i = 0; i < 3; i++) {
      state.answer(Exercise(often), false, countsToday: false);
    }
    expect(state.reviews[often.id]!.misses, 3);
    expect(state.reviews[once.id]!.misses, 1);
    expect(state.reviews[often.id]!.lastMissed, isNotNull);

    // Both due now: the often-missed word is picked first.
    state.settings(5);
    final session = state.makeSession();
    final reviews = session.where((e) => e.misses > 0).toList();
    expect(reviews.first.word.id, often.id);
    expect(reviews.first.oftenMissed, isTrue);

    // A clean answer moves forward; more misses mean a shorter wait.
    state.answer(Exercise(once, review: true), true, countsToday: false);
    state.answer(Exercise(often, review: true), true, countsToday: false);
    expect(state.reviews[often.id]!.stage, 1);
    expect(LearningService.interval(2, 1), const Duration(days: 7));
    expect(LearningService.interval(2, 3), const Duration(hours: 84));
    expect(LearningService.interval(0, 5), const Duration(days: 1));
  });

  test('Reviews are spread between new questions', () {
    final fresh = [for (final w in playableWords.take(6)) Exercise(w)];
    final reviews = [
      for (final w in playableWords.skip(6).take(4))
        Exercise(w, review: true, misses: 1)
    ];
    final order = LearningService.spread([...reviews, ...fresh])
        .map((e) => e.review ? 'R' : 'N')
        .join();
    expect(order, 'NNRNRNRNRN');
    expect(LearningService.spread(reviews).length, 4);
  });

  test('Practice label tells new, revisit and missed reviews apart', () {
    final w = playableWords.first;
    final now = DateTime(2026, 10, 15, 9);
    expect(Exercise(w).label(now), '새로운 표현');
    expect(Exercise(w, review: true).label(now), '다시 만나는 표현');
    expect(
        Exercise.fromReview(
                w, ReviewEntry(w.id, lastMissed: DateTime(2026, 10, 14, 23)))
            .label(now),
        '복습 · 어제 틀림');
    expect(
        Exercise.fromReview(w,
                ReviewEntry(w.id, misses: 3, lastMissed: DateTime(2026, 10, 10)))
            .label(now),
        '복습 · 5일 전 틀림 · 3번 틀림');
    // Older saved records have no miss date.
    final old = ReviewEntry.fromJson(
        {'id': w.id, 'stage': 1, 'due': '2026-10-01T00:00:00.000'});
    expect((old.misses, old.lastMissed), (1, null));
    expect(Exercise.fromReview(w, old).label(now), '복습 · 전에 틀림');
    // An older record not yet answered correctly was due when it was missed.
    final unanswered = ReviewEntry.fromJson(
        {'id': w.id, 'stage': 0, 'due': '2026-10-12T20:00:00.000'});
    expect(Exercise.fromReview(w, unanswered).label(now), '복습 · 3일 전 틀림');
  });

  test('Older level streaks become experience', () {
    final progress = LearningProgress()
      ..restore({
        'goal': 10,
        'adaptiveLevel20': 3,
        'levelStreak': ['a', 'b'],
        'levelMisses': 1,
        'day': 'old',
        'completed': 0,
        'correct': 0,
        'seen': <String>[],
        'reviews': <Object>[],
        'writing': <String, String>{},
      }, {}, {});
    expect((progress.level, progress.xp), (3, 2));
    expect(progress.xpWords, {'a', 'b'});
  });
}
