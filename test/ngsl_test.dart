import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support.dart';

import 'package:edu_voca/data/local/ngsl_data.dart';

void main() {
  test('Every word has a complete bilingual sentence with one target blank',
      () {
    final examples =
        jsonDecode(File('data/examples/selected.json').readAsStringSync())
            as Map;
    expect(examples, hasLength(2833));
    for (final word in playableWords) {
      expect(word.isVocabulary, isFalse, reason: word.id);
      expect('____'.allMatches(word.sentence).length, 1, reason: word.id);
      expect(word.sentence.replaceAll('____', '').trim().length, greaterThan(5),
          reason: word.id);
      expect(RegExp('[가-힣]').hasMatch(word.translation), isTrue,
          reason: word.id);
      expect(word.translation, isNot(word.meaning), reason: word.id);
      expect(word.exampleCredit, isNotEmpty, reason: word.id);
      expect(word.accepts(word.answer), isTrue, reason: word.id);
      if (word.isPhrase) continue;
      final row = examples[word.id] as Map;
      expect(
          (row['sentence'] as String)
              .replaceFirst('____', row['answer'] as String),
          row['complete']);
    }
  });
  test(
      'Inflected answers retain the headword and Korean glossary for the catalog',
      () {
    final inflected = playableWords.firstWhere(
        (w) => w.answer.toLowerCase() != w.id && w.isVocabulary == false);
    expect(inflected.headword.toLowerCase(), inflected.id);
    expect(inflected.meaning, isNotEmpty);
    expect(inflected.accepts(inflected.answer.toUpperCase()), isTrue);
    expect(inflected.accepts(inflected.id), isFalse);
  });
  test('Frequency stars use source quintiles and preserve missing data', () {
    for (final pair in [
      (1, 5),
      (562, 5),
      (563, 4),
      (1124, 4),
      (1125, 3),
      (1686, 3),
      (1687, 2),
      (2248, 2),
      (2249, 1),
      (2809, 1)
    ]) {
      final word = WordItem.vocabulary('sample', 1, '예시', 'example',
          ngslRank: pair.$1, studyOrder: 1);
      expect(word.frequencyStars, pair.$2);
    }
    const spoken = WordItem.vocabulary('two', 1, '둘', 'number',
        spokenRank: 721, spokenCore: true, studyOrder: 1);
    expect(spoken.frequencyStars, 1);
    expect(spoken.frequencyLabel, '회화 빈도');
    expect(
        wordsById['water']!.frequencyStars, 5); // General rank takes priority.
    expect(
        wordsById['true']!.frequencyStars, isNotNull); // General rank exists.
    expect(
        wordsById['pickup']!.frequencyStars, isNull); // Legacy phrase, no rank.
  });
  test('All official words, ranks and Korean meanings are available offline',
      () {
    expect(playableWords.where((w) => !w.isPhrase), hasLength(2833));
    expect(playableWords, hasLength(2897));
    expect(playableWords.map((w) => w.id).toSet(), hasLength(2897));
    expect(playableWords.where((w) => w.ngslRank != null), hasLength(2809));
    expect(playableWords.where((w) => w.spokenCore), hasLength(721));
    expect(playableWords.where((w) => w.spokenCore && w.ngslRank != null),
        hasLength(697));
    expect(playableWords.map((w) => w.level).toSet(),
        containsAll(List.generate(50, (i) => i + 1)));
    final data =
        jsonDecode(File('assets/data/ngsl.json').readAsStringSync()) as Map;
    expect(data['license'], 'CC-BY-SA-4.0');
    final rows = data['words'] as List;
    for (var i = 0; i < rows.length; i++) {
      final word = ngslVocabulary[i];
      final row = rows[i] as Map;
      expect(word.id, row['id']);
      expect(word.ngslRank, row['ngslRank']);
      expect(word.spokenRank, row['spokenRank']);
      expect(word.translation, row['korean']);
      expect(word.note, row['definition']);
      expect(RegExp('[가-힣]').hasMatch(word.translation), isTrue,
          reason: word.id);
      expect(word.note, isNotEmpty);
      expect(word.accepts(word.answer.toUpperCase()), isTrue);
      expect(word.accepts(''), isFalse);
    }
  });
  test('Publisher rank gaps stay missing and number words are not dropped', () {
    expect(wordsById['true']!.spokenCore, isTrue);
    expect(wordsById['true']!.spokenRank, isNull);
    expect(wordsById['true']!.rankLabel, contains('순위 미제공'));
    expect(wordsById['two']!.ngslRank, isNull);
    expect(wordsById['two']!.spokenCore, isTrue);
    expect(wordsById['email']!.note, contains('electronically'));
    expect(wordsById['i']!.answer, 'I');
  });
  test('All 20 levels focus on their CEFR band and retain basics', () {
    final state = createLearning()..settings(10);
    for (var level = 1; level <= 20; level++) {
      state.settings(10, startingLevel: level);
      final session = state.makeSession();
      final target = (level - 1) ~/ 4 + 1;
      expect(session, hasLength(10));
      expect(session.where((e) => e.word.difficultyStars == target).length,
          greaterThanOrEqualTo(7));
      if (target > 1) {
        expect(
            session.any((e) =>
                e.word.difficultyStars != null &&
                e.word.difficultyStars! < target),
            isTrue);
      }
      expect(session.map((e) => e.word.id).toSet(), hasLength(10));
    }
  });
  test('Oxford classification is explicit and conservative', () {
    expect(playableWords.where((w) => w.cefr != null), hasLength(2429));
    expect(wordsById['about']!.cefr, isNull);
    expect(wordsById['ability']!.cefr, 'A2');
    expect(wordsById['ability']!.difficultyStars, 2);
    expect(wordsById['absence']!.cefr, 'C1');
    expect(wordsById['absence']!.difficultyStars, 5);
  });
  test('Existing phrase reviews and progress survive data replacement',
      () async {
    SharedPreferences.setMockInitialValues({
      'daily_english_v1': jsonEncode({
        'goal': 10,
        'level': 8,
        'day': LearningViewModel.dateKey(DateTime.now()),
        'completed': 12,
        'correct': 9,
        'recent': [true],
        'seen': ['love', 'pickup'],
        'reviews': [
          ReviewEntry('pickup').toJson(),
          ReviewEntry('sounds').toJson()
        ],
        'writing': {'hotel': 'My answer'},
      })
    });
    final state =
        createLearning(preferences: await SharedPreferences.getInstance());
    expect(state.storageError, isNull);
    expect(state.level, 1);
    expect(state.completed, 12);
    expect(state.learned, {'love'});
    expect(state.writingReviews['hotel'], 'My answer');
    expect(state.reviews.keys, containsAll(['pickup', 'sounds']));
    expect(state.makeSession().any((e) => e.word.id == 'pickup'), isTrue);
    state.answer(Exercise(wordsById['pickup']!, review: true), true,
        countsToday: true);
    expect(state.reviews['pickup']!.stage, 1);
  });
  test('Adaptive level and streak survive restart', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final state = createLearning(preferences: prefs)
      ..settings(10, startingLevel: 8);
    final a2 =
        playableWords.where((w) => w.difficultyStars == 2).take(3).toList();
    state.answer(Exercise(a2[0]), true, countsToday: true);
    state.answer(Exercise(a2[1]), true, countsToday: true);
    await state.flush();
    final restored = createLearning(preferences: prefs);
    expect((restored.level, restored.xp, restored.xpToNext), (8, 2, 11));
    expect(restored.completed, 2);
    // Words already counted stay counted after a restart.
    expect(restored.answer(Exercise(a2[0]), true, countsToday: true).gained, 0);
    restored.answer(Exercise(a2[2]), true, countsToday: true);
    expect(restored.xp, 3);
  });
}
