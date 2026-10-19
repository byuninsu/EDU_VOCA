import 'package:edu_voca/domain/models/scenario.dart';
import 'package:edu_voca/domain/models/writing_feedback.dart';

/// Grades a learner's reply to one turn of a role-play conversation.
abstract class WritingEvaluator {
  Future<WritingFeedback> evaluate(Scenario scenario, int turn, String answer);
}

/// Uses [primary] (AI) and falls back to [fallback] when it is unavailable,
/// for example offline, over the free quota or before App Check is set up.
class FallbackWritingEvaluator implements WritingEvaluator {
  final WritingEvaluator primary, fallback;
  const FallbackWritingEvaluator(this.primary, this.fallback);

  @override
  Future<WritingFeedback> evaluate(
      Scenario scenario, int turn, String answer) async {
    try {
      return await primary.evaluate(scenario, turn, answer);
    } catch (_) {
      return fallback.evaluate(scenario, turn, answer);
    }
  }
}

/// Simple on-device check against the scenario's model answers. It cannot
/// judge free wording, so it only gives a rough grade.
class OfflineWritingEvaluator implements WritingEvaluator {
  const OfflineWritingEvaluator();

  static const _minor = {
    'a', 'an', 'the', 'i', 'you', 'we', 'my', 'is', 'am', 'are', 'be', 'to',
    'please', 'could', 'can', 'would', 'will', 'me', 'it', 'do', 'have',
    'get', 'like', 'there', 'name', 'under', 'with', 'for', 'of'
  };
  static const _contractions = {
    "i'd": 'i would', "i'm": 'i am', "i've": 'i have', "it's": 'it is',
    "what's": 'what is', "where's": 'where is', "can't": 'can not',
    "don't": 'do not', "we'd": 'we would', "we're": 'we are',
  };

  static List<String> words(String text) {
    var value = text.toLowerCase().replaceAll('’', "'");
    _contractions.forEach((short, long) =>
        value = value.replaceAll(RegExp("\\b$short\\b"), long));
    return value
        .replaceAll(RegExp(r"[^a-z' ]"), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
  }

  /// Capitalized words after the first one are treated as names.
  static Set<String> _names(String text) => RegExp(r"(?<=\s)[A-Z][a-z]+")
      .allMatches(text)
      .map((m) => m[0]!.toLowerCase())
      .toSet();

  @override
  Future<WritingFeedback> evaluate(
      Scenario scenario, int turn, String answer) async {
    final step = scenario.turns[turn];
    final given = words(answer);
    final references = [step.example, ...step.alternatives];
    final names = references.expand(_names).toSet();
    String strip(List<String> w) =>
        w.where((x) => !names.contains(x)).join(' ');
    if (references.any((r) => strip(words(r)) == strip(given))) {
      return const WritingFeedback(
          WritingGrade.veryGood, '예시 답안과 같은 자연스러운 표현이에요!',
          offline: true);
    }
    var bestScore = -1.0;
    var missing = <String>[];
    for (final reference in references) {
      final keys = words(reference)
          .where((w) => !_minor.contains(w) && !names.contains(w))
          .toSet();
      if (keys.isEmpty) continue;
      final lacking = keys.where((k) => !given.contains(k)).toList();
      final score = 1 - lacking.length / keys.length;
      if (score > bestScore) {
        bestScore = score;
        missing = lacking;
      }
    }
    if (bestScore >= .75) {
      return WritingFeedback(
          WritingGrade.good, '뜻은 전달돼요.\n예시 문장과 비교해 표현을 다듬어 봐요.',
          betterAnswer: step.example, offline: true);
    }
    return WritingFeedback(
        WritingGrade.retry,
        missing.isEmpty
            ? '상황에 맞는 핵심 표현을 넣어 다시 써 볼까요?'
            : '핵심 표현이 빠졌어요.\n"${missing.first}" 같은 단어를 넣어 다시 써 볼까요?',
        offline: true);
  }
}
