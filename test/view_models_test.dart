import 'package:flutter_test/flutter_test.dart';
import 'package:edu_voca/data/repositories/memory_progress_repository.dart';
import 'package:edu_voca/domain/repositories/progress_repository.dart';
import 'package:edu_voca/features/learning/view_models/word_practice_view_model.dart';
import 'package:edu_voca/features/writing/view_models/writing_view_model.dart';
import 'package:edu_voca/domain/models/writing_feedback.dart';
import 'package:edu_voca/features/settings/view_models/settings_view_model.dart';
import 'package:edu_voca/features/vocabulary/view_models/vocabulary_view_model.dart';
import 'support.dart';
import 'package:edu_voca/domain/services/word_cues.dart';

class FailingRepository implements ProgressRepository {
  @override
  Map<String, dynamic>? load() => null;
  @override
  Future<void> save(Map<String, dynamic> snapshot) async =>
      throw StateError('offline');
}

void main() {
  test('Paid hint is not a hit; free similar-word hint preserves credit',
      () async {
    final learning = createLearning();
    final vm = WordPracticeViewModel(
        learning: learning,
        exercises: [
          Exercise(wordsById['check']!),
          Exercise(wordsById['help']!),
          Exercise(wordsById['check']!)
        ],
        countsToday: true);
    vm.showHint();
    expect(vm.firstLetter, 'c');
    expect(learning.completed, 0);
    vm.submit('bill');
    expect(vm.usedHint, isTrue);
    expect(vm.correct, isNull);
    vm.submit('check');
    vm.submit('check');
    expect(vm.correct, isFalse);
    expect(vm.solvedWithHint, isTrue);
    expect(learning.completed, 1);
    expect(learning.correctToday, 0);
    expect(learning.reviews.keys, contains('check'));
    vm.next();
    expect(vm.hintVisible, isFalse);
    expect(vm.usedHint, isFalse);
    vm.submit('assist');
    expect(vm.correct, isNull);
    expect(vm.hintVisible, isTrue);
    expect(vm.usedHint, isFalse);
    vm.showHint(); // Already-visible free hint must remain free.
    vm.submit(' HELP ');
    expect(vm.correct, isTrue);
    expect(vm.hits, 1);
    expect(learning.correctToday, 1);
    vm.next();
    vm.submit('bill');
    expect(vm.correct, isNull);
    vm.reveal();
    expect(vm.correct, isFalse);
    await learning.flush();
    vm.dispose();
    learning.dispose();
  });
  test('Translation cues locate Korean text without highlighting the sentence',
      () {
    expect(WordCues.translationFocus(wordsById['water']!), '물');
    expect(WordCues.translationFocus(wordsById['love']!), '사랑해');
    expect(WordCues.translationFocus(wordsById['help']!), '도와');
    for (final word in vocabulary.words.where((w) => w.isPhrase)) {
      expect(WordCues.translationFocus(word), isNotNull, reason: word.id);
    }
    expect(WordCues.isSimilar(wordsById['help']!, 'wrong'), isFalse);
    expect(WordCues.isSimilar(wordsById['help']!, 'help'), isFalse);
  });
  test('Expressions join regular sessions, accept spaces and retain review IDs',
      () async {
    final learning = createLearning();
    final phrases = vocabulary.words.where((w) => w.isPhrase).toList();
    expect(phrases, hasLength(64));
    expect(phrases.map((w) => w.id).toSet(), hasLength(64));
    for (final phrase in phrases) {
      expect(phrase.ngslRank, isNull);
      expect(phrase.cefr, isNull);
      expect('____'.allMatches(phrase.sentence).length, 1);
      expect(phrase.accepts(phrase.answer.toUpperCase().replaceAll(' ', '   ')),
          isTrue);
    }
    final session = learning.makeSession();
    expect(session.where((e) => e.word.isPhrase), hasLength(2));
    final pickup = wordsById['pickup']!;
    expect(phrases, contains(pickup));
    learning.answer(Exercise(pickup), false, countsToday: true);
    expect(learning.makeSession().any((e) => e.word.id == 'pickup' && e.review),
        isTrue);
    learning.answer(Exercise(pickup, review: true), true, countsToday: false);
    expect(learning.level, 1);
    expect(learning.learned, contains('pickup'));
    await learning.flush();
    final restored = LearningViewModel(
        repository: learning.repository, vocabulary: vocabulary);
    expect(restored.learned, contains('pickup'));
    expect(restored.reviews['pickup']!.stage, 1);
    final catalog = VocabularyViewModel(vocabulary)
      ..filterSpoken(true)
      ..filterPhrases(true);
    expect(catalog.spokenOnly, isFalse);
    expect(catalog.matches, hasLength(64));
    catalog.search('데리러');
    expect(catalog.matches.single.id, 'pickup');
    catalog.dispose();
    learning.dispose();
    restored.dispose();
  });
  test(
      'Practice retries do not grade, reveal grades only once, continue resets',
      () async {
    final learning = createLearning();
    final vm = WordPracticeViewModel(
        learning: learning,
        exercises: [Exercise(wordsById['love']!)],
        countsToday: true);
    vm.submit('');
    expect(vm.tone, GuideTone.wrong);
    vm.submit('wrong');
    vm.submit('still wrong');
    vm.next();
    expect(learning.completed, 0);
    expect(vm.finished, isFalse);
    vm.reveal();
    vm.reveal();
    vm.submit('love');
    expect(learning.completed, 1);
    expect(learning.correctToday, 0);
    expect(learning.reviews.keys, contains('love'));
    vm.next();
    expect(vm.finished, isTrue);
    vm.continuePractice();
    expect(vm.finished, isFalse);
    expect(vm.correct, isNull);
    expect(vm.hits, 0);
    await learning.flush();
    vm.dispose();
    learning.dispose();
  });
  test('Injected storage round-trips final snapshot and writing state',
      () async {
    final repo = MemoryProgressRepository();
    final learning =
        LearningViewModel(repository: repo, vocabulary: vocabulary);
    final settings = SettingsViewModel(learning)
      ..setLevel(8)
      ..setGoal(15)
      ..save();
    final writing =
        WritingViewModel(learning: learning, scenario: scenarios.first);
    await writing.evaluate('');
    expect(writing.feedback, isNull);
    await writing.evaluate(' I have reservation under Daniel ');
    expect(writing.feedback!.grade, WritingGrade.good);
    await learning.flush();
    final restored =
        LearningViewModel(repository: repo, vocabulary: vocabulary);
    expect(restored.level, 8);
    expect(restored.dailyGoal, 15);
    expect(restored.writingReviews['hotel'],
        '0\tI have reservation under Daniel');
    writing.tryAgain();
    await writing.evaluate('I have a reservation under Daniel.');
    expect(writing.feedback!.grade, WritingGrade.veryGood);
    // A weak turn keeps the conversation in review until a clean run.
    expect(learning.writingReviews, hasLength(1));
    settings.dispose();
    writing.dispose();
    learning.dispose();
    restored.dispose();
  });
  test('Storage errors are surfaced and pending save is safe after dispose',
      () async {
    final learning = LearningViewModel(
        repository: FailingRepository(), vocabulary: vocabulary);
    learning.settings(15);
    await learning.flush();
    expect(learning.storageError, isNotNull);
    learning.settings(20);
    learning.dispose();
    await learning.flush();
  });
  test('Catalog searches and filters without a widget', () {
    final vm = VocabularyViewModel(vocabulary)..search(' WATER ');
    expect(vm.matches.map((w) => w.id), contains('water'));
    vm.search('');
    vm.filterSpoken(true);
    expect(vm.matches, hasLength(721));
    vm.dispose();
  });
}
