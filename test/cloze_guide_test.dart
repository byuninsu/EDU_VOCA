import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edu_voca/data/repositories/memory_progress_repository.dart';
import 'package:edu_voca/domain/models/cloze_cue.dart';
import 'package:edu_voca/domain/repositories/vocabulary_repository.dart';
import 'package:edu_voca/domain/services/cloze_judge.dart';
import 'package:edu_voca/features/learning/view_models/word_practice_view_model.dart';
import 'package:edu_voca/features/learning/views/word_practice.dart';
import 'support.dart';
import 'widget_test.dart' show phone;

/// The real vocabulary with test cues instead of the generated ones.
class CuedVocabulary implements VocabularyRepository {
  @override
  final Map<String, ClozeCue> clozeCues;
  CuedVocabulary(this.clozeCues);
  @override
  List<WordItem> get words => vocabulary.words;
  @override
  Map<String, WordItem> get byId => vocabulary.byId;
  @override
  List<Scenario> get scenarios => vocabulary.scenarios;
}

LearningViewModel cuedLearning() => LearningViewModel(
    repository: MemoryProgressRepository(),
    vocabulary: CuedVocabulary(const {
      'help': ClozeCue(sameMeaning: ['aid'], wrongForms: ['helping', 'helps']),
    }));

Text guideText(WidgetTester tester) =>
    tester.widget<Text>(find.byWidgetPredicate((w) =>
        w is Text &&
        w.key is ValueKey<String> &&
        (w.key! as ValueKey<String>).value.startsWith('GuideTone.')));

void main() {
  test('Prepared cues, listed synonyms and near spellings judge instantly',
      () {
    final help = wordsById['help']!;
    const cue = ClozeCue(sameMeaning: ['aid'], wrongForms: ['helping']);
    expect(LocalClozeCheck.judge(help, ' AID ', cue), ClozeVerdict.sameMeaning);
    expect(LocalClozeCheck.judge(help, 'assist'), ClozeVerdict.sameMeaning);
    expect(LocalClozeCheck.judge(help, 'helping', cue), ClozeVerdict.wrongForm);
    expect(LocalClozeCheck.judge(wordsById['water']!, 'watr'),
        ClozeVerdict.spelling);
    expect(LocalClozeCheck.judge(help, 'table', cue), ClozeVerdict.unrelated);

    // Generated data: every list belongs to a real blank and excludes its answer.
    final cues = vocabulary.clozeCues;
    expect(cues.length, greaterThan(2000));
    for (final MapEntry(:key, :value) in cues.entries) {
      final answer = normalize(wordsById[key]!.answer);
      expect([...value.sameMeaning, ...value.wrongForms].map(normalize),
          isNot(contains(answer)), reason: key);
    }
    final initially = wordsById['initially']!;
    expect(LocalClozeCheck.judge(initially, 'at first', cues['initially']),
        ClozeVerdict.sameMeaning);
    expect(LocalClozeCheck.judge(wordsById['go']!, 'went', cues['go']),
        ClozeVerdict.wrongForm);
  });

  test('Guides change per verdict; same meaning is a free hint', () {
    final learning = cuedLearning();
    final vm = WordPracticeViewModel(
        learning: learning,
        exercises: [Exercise(wordsById['help']!)],
        countsToday: true);
    expect(vm.guide, WordPracticeViewModel.idleGuide);
    vm.submit('helping');
    expect(vm.tone, GuideTone.close);
    expect(vm.guide, contains('형태'));
    vm.submit('table');
    expect(vm.tone, GuideTone.wrong);
    vm.submit('aid');
    expect(vm.tone, GuideTone.hint);
    expect(vm.guide, contains("'h'로 시작하는 단어도 생각해 보세요"));
    expect(vm.hintVisible, isTrue);
    expect(vm.usedHint, isFalse);
    vm.submit('help');
    expect(vm.correct, isTrue);
    vm.dispose();
    learning.dispose();
  });

  testWidgets('Hint puts the first letter in the blank; finishing auto-checks',
      (tester) async {
    phone(tester);
    final learning = createLearning();
    addTearDown(learning.dispose);
    await tester.pumpWidget(MaterialApp(
        home: WordPractice(
            state: learning,
            exercises: [Exercise(wordsById['water']!)],
            countsToday: true)));
    expect(guideText(tester).data, '빈칸을 눌러 입력하세요.');
    await tester.tap(find.text('힌트 보기'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'w'), findsOneWidget);
    expect(guideText(tester).data, "'w'로 시작하는 표현이에요.");
    await tester.enterText(find.byType(TextField), 'water');
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(learning.correctToday, 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Same-meaning word changes colour, prefills, keeps credit',
      (tester) async {
    phone(tester);
    final learning = cuedLearning();
    addTearDown(learning.dispose);
    await tester.pumpWidget(MaterialApp(
        home: WordPractice(
            state: learning,
            exercises: [Exercise(wordsById['help']!)],
            countsToday: true)));
    final idle = guideText(tester).style!.color;
    // Different length, but a prepared same-meaning word: judged right away.
    await tester.enterText(find.byType(TextField), 'aid');
    await tester.pumpAndSettle();
    final guide = guideText(tester);
    expect(guide.data, contains("'aid'도 뜻은 같아요"));
    expect(guide.style!.color, isNot(idle));
    expect(find.widgetWithText(TextField, 'h'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'help');
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(learning.correctToday, 1);
    await tester.pumpWidget(const SizedBox());
  });

  test('Adjective for an adverb blank names the fitting form', () {
    final word = wordsById['particularly']!;
    final cue = vocabulary.clozeCues['particularly'];
    expect(LocalClozeCheck.judge(word, 'special', cue),
        ClozeVerdict.partOfSpeech);
    final slip = LocalClozeCheck.slip(word, 'special', cue)!;
    expect((slip.fix, slip.needsAdverb, slip.isAnswer),
        ('specially', true, false));
    // The answer's own adjective: the answer itself stays hidden.
    expect(LocalClozeCheck.slip(word, 'particular', cue)!.isAnswer, isTrue);
    expect(LocalClozeCheck.slip(word, 'table', cue), isNull);
  });

  testWidgets('Adjective guess explains the adverb slot after a pause',
      (tester) async {
    phone(tester);
    final learning = LearningViewModel(
        repository: MemoryProgressRepository(), vocabulary: vocabulary);
    addTearDown(learning.dispose);
    await tester.pumpWidget(MaterialApp(
        home: WordPractice(
            state: learning,
            exercises: [Exercise(wordsById['particularly']!)],
            countsToday: true)));
    await tester.enterText(find.byType(TextField), 'special');
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(guideText(tester).data,
        "'special'도 뜻은 비슷해요!\n하지만 형용사라서 이 자리에는 안 맞아요.\n"
        "여기는 부사 자리라 'specially'처럼 써야 해요.\n다른 단어도 생각해 보세요.");
    await tester.enterText(find.byType(TextField), 'specially');
    await tester.pumpAndSettle();
    expect(guideText(tester).data, contains("'specially'도 뜻은 같아요"));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  test('Generated cues accept specially for particularly', () {
    expect(vocabulary.clozeCues['particularly']!.sameMeaning,
        containsAll(['especially', 'specially']));
  });

  testWidgets('In-app keyboard types, moves between phrase blanks, deletes',
      (tester) async {
    phone(tester);
    final learning = createLearning();
    addTearDown(learning.dispose);
    await tester.pumpWidget(MaterialApp(
        home: WordPractice(
            state: learning,
            exercises: [Exercise(wordsById['atfirst']!)],
            countsToday: true)));
    final fields = find.byType(TextField);
    expect(tester.widget<TextField>(fields.first).keyboardType,
        TextInputType.none);
    Future<void> press(String keys) async {
      for (final key in keys.split('')) {
        await tester.tap(find.byKey(ValueKey('key-$key')));
        await tester.pump();
      }
    }

    await press('ax');
    await tester.tap(find.byKey(const ValueKey('key-⌫')));
    await tester.pump();
    await press('t');
    // "at" is full, so the next letters go to the second blank.
    await press('first');
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(learning.correctToday, 1);
    expect(find.byKey(const ValueKey('key-q')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Long sentences shrink to two lines; keyboard leaves no scroll',
      (tester) async {
    phone(tester);
    // The test font draws square glyphs; Arial approximates Roboto's widths.
    await tester.runAsync(() async {
      final loader = FontLoader('Real');
      for (final name in ['arial.ttf', 'arialbd.ttf']) {
        final bytes = File('C:/Windows/Fonts/$name').readAsBytesSync();
        loader.addFont(Future.value(ByteData.sublistView(bytes)));
      }
      await loader.load();
    });
    final longest = [...wordsById.values]
      ..sort((a, b) => b.sentence.length.compareTo(a.sentence.length));
    for (final word in longest.take(15)) {
      await tester.pumpWidget(MaterialApp(
          theme: ThemeData(fontFamily: 'Real'),
          home: WordPractice(
              key: ValueKey(word.id),
              state: createLearning(),
              exercises: [Exercise(word)],
              countsToday: true)));
      final paragraph = tester.renderObject<RenderParagraph>(find
          .ancestor(
              of: find.byKey(const ValueKey('cloze-answer-line')),
              matching: find.byType(RichText))
          .first);
      final size = paragraph.text.style!.fontSize!;
      expect(paragraph.size.height, lessThanOrEqualTo(size * 1.65 * 2 + 4),
          reason: '${word.id}: ${word.sentence}');
      final scroll = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position;
      expect(scroll.maxScrollExtent, 0, reason: word.id);
    }
    await tester.pumpWidget(const SizedBox());
  });
}
