import 'cloze_example.dart';

class WordItem {
  final String id, sentence, translation, answer, note;
  final int level;
  final List<String> alternatives;
  final int? ngslRank, spokenRank;
  final bool spokenCore, isVocabulary;
  final int studyOrder;
  final String? lemma, meaning;
  final String? cefr;
  final String? exampleCredit;
  final String? translationFocus;
  final List<String> partsOfSpeech;
  bool get isPhrase => headword.contains(' ');

  const WordItem.phrase(this.id, String phrase, String gloss, this.sentence,
      this.translation, this.answer, this.note,
      [this.alternatives = const []])
      : partsOfSpeech = const [],
        translationFocus = null,
        level = 0,
        lemma = phrase,
        meaning = gloss,
        cefr = null,
        ngslRank = null,
        spokenRank = null,
        spokenCore = false,
        isVocabulary = false,
        studyOrder = 10000,
        exampleCredit = '앱 작성 숙어·구동사 예문·해석 (AI 작성)';
  const WordItem(this.id, this.level, this.sentence, this.translation,
      this.answer, this.note,
      [this.alternatives = const []])
      : partsOfSpeech = const [],
        translationFocus = null,
        exampleCredit = '앱 작성 예문·해석 (AI 작성)',
        cefr = null,
        ngslRank = null,
        spokenRank = null,
        spokenCore = false,
        isVocabulary = false,
        studyOrder = 0,
        lemma = null,
        meaning = null;

  const WordItem.vocabulary(
      String word, this.level, this.translation, this.note,
      {this.ngslRank,
      this.spokenRank,
      this.spokenCore = false,
      required this.studyOrder,
      this.cefr})
      : partsOfSpeech = const [],
        translationFocus = null,
        exampleCredit = null,
        id = word,
        answer = word == 'i' ? 'I' : word,
        sentence = '____',
        alternatives = const [],
        isVocabulary = true,
        lemma = word,
        meaning = translation;

  WordItem.withExample(WordItem entry, WordItem example)
      : partsOfSpeech = entry.partsOfSpeech,
        translationFocus = example.translationFocus,
        exampleCredit = example.exampleCredit,
        cefr = entry.cefr,
        id = entry.id,
        level = entry.level,
        sentence = example.sentence,
        translation = example.translation,
        answer = example.answer,
        note = '${example.note}\n\n${entry.note}',
        alternatives = example.alternatives,
        ngslRank = entry.ngslRank,
        spokenRank = entry.spokenRank,
        spokenCore = entry.spokenCore,
        isVocabulary = false,
        studyOrder = entry.studyOrder,
        lemma = entry.headword,
        meaning = entry.translation;

  WordItem.withCefr(WordItem entry, this.cefr, {List<String>? partsOfSpeech})
      : partsOfSpeech = partsOfSpeech ?? entry.partsOfSpeech,
        translationFocus = entry.translationFocus,
        exampleCredit = entry.exampleCredit,
        id = entry.id,
        level = entry.level,
        sentence = entry.sentence,
        translation = entry.translation,
        answer = entry.answer,
        note = entry.note,
        alternatives = entry.alternatives,
        ngslRank = entry.ngslRank,
        spokenRank = entry.spokenRank,
        spokenCore = entry.spokenCore,
        isVocabulary = entry.isVocabulary,
        studyOrder = entry.studyOrder,
        lemma = entry.lemma,
        meaning = entry.meaning;

  WordItem.withCloze(WordItem entry, ClozeExample example)
      : partsOfSpeech = entry.partsOfSpeech,
        translationFocus = example.translationFocus,
        id = entry.id,
        level = entry.level,
        sentence = example.sentence,
        translation = example.translation,
        answer = example.answer,
        note = entry.note,
        alternatives = const [],
        ngslRank = entry.ngslRank,
        spokenRank = entry.spokenRank,
        spokenCore = entry.spokenCore,
        isVocabulary = false,
        studyOrder = entry.studyOrder,
        lemma = entry.headword,
        meaning = entry.meaning ?? entry.translation,
        cefr = entry.cefr,
        exampleCredit = example.credit;

  String get headword => lemma == 'i' ? 'I' : lemma ?? answer;
  int? get difficultyStars => cefr == null
      ? null
      : const ['A1', 'A2', 'B1', 'B2', 'C1'].indexOf(cefr!) + 1;
  // Relative rank bands within one source list, not absolute usage counts.
  int? get frequencyStars {
    final rank = ngslRank ?? spokenRank;
    if (rank == null) return null;
    final total = ngslRank != null ? 2809 : 721;
    return (5 - ((rank - 1) * 5 ~/ total)).clamp(1, 5);
  }

  String get frequencyLabel => ngslRank != null ? '일반 빈도' : '회화 빈도';
  String get frequencyExplanation {
    final rank = ngslRank ?? spokenRank;
    if (rank == null) return '공식 빈도 순위가 없어 별점을 표시하지 않아요.';
    final source = ngslRank != null ? 'NGSL' : 'NGSL-Spoken';
    final total = ngslRank != null ? 2809 : 721;
    return '$source $total개 중 $rank위 · 별 $frequencyStars/5\n'
        '목록 내 순위를 20%씩 나눠 상위 구간부터 별 5~1개로 표시해요.\n'
        '일반 순위를 우선하고, 없으면 회화 순위를 사용해요.\n실제 사용 횟수는 아니에요.';
  }

  String get rankLabel => [
        if (ngslRank != null) '일반 빈도 $ngslRank위',
        if (spokenRank != null) '회화 빈도 $spokenRank위',
        if (spokenCore && spokenRank == null) '회화 핵심 · 순위 미제공',
      ].join(' · ');
  String get spellingHint => '${answer[0]}로 시작 · ${answer.length}글자';
  String get complete => sentence.replaceFirst('____', answer);

  /// Articles, prepositions, pronouns, conjunctions and similar grammar words.
  /// Words that can also be a noun, verb or adjective (like, right) are not.
  bool get isFunctionWord {
    if (isPhrase || partsOfSpeech.isEmpty) return false;
    if (partsOfSpeech.any(const {'명사', '동사', '형용사', '연결동사'}.contains)) {
      return false;
    }
    return partsOfSpeech.any(const {'전치사', '접속사'}.contains) ||
        !partsOfSpeech.any(const {'부사', '동사구', '부사구', '형용사구'}.contains);
  }

  /// Nouns and unlabeled items; verbs, adjectives and adverbs are favored.
  bool get isNounLike =>
      !isPhrase &&
      !isFunctionWord &&
      !partsOfSpeech.any(
          const {'동사', '형용사', '부사', '연결동사', '동사구', '부사구', '형용사구'}.contains);
  bool accepts(String input) =>
      [answer, ...alternatives].map(normalize).contains(normalize(input));
}

String normalize(String value) => value
    .trim()
    .toLowerCase()
    .replaceAll(RegExp(r"[.!?,]+$"), '')
    .replaceAll(RegExp(r'\s+'), ' ');
