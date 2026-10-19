import 'package:edu_voca/domain/models/cloze_cue.dart';
import 'package:edu_voca/domain/models/word_item.dart';
import 'package:edu_voca/domain/services/word_cues.dart';

/// Why a non-matching blank answer is wrong; guides the next attempt.
enum ClozeVerdict {
  /// A different word that fits with the same meaning.
  sameMeaning,

  /// The target word in the wrong form (tense, plural, ...).
  wrongForm,

  /// The target or a same-meaning word as an adjective where an adverb is
  /// needed, or the reverse; see [LocalClozeCheck.slip].
  partOfSpeech,

  /// A misspelling of the target.
  spelling,

  /// Anything else.
  unrelated,
}

/// An adjective typed for an adverb blank, or the reverse.
class PartOfSpeechSlip {
  /// The form that fits the blank, e.g. `specially` for `special`.
  final String fix;

  /// Whether the blank needs an adverb (otherwise an adjective).
  final bool needsAdverb;

  /// Whether [fix] is the answer itself, so it must not be shown.
  final bool isAnswer;
  const PartOfSpeechSlip(this.fix,
      {required this.needsAdverb, required this.isAnswer});
}

/// Instant, offline judgement from prepared cues and near spellings.
class LocalClozeCheck {
  static ClozeVerdict judge(WordItem word, String input, [ClozeCue? cue]) {
    final given = normalize(input), target = normalize(word.answer);
    if (WordCues.isSimilar(word, input) ||
        (cue?.sameMeaning.map(normalize).contains(given) ?? false)) {
      return ClozeVerdict.sameMeaning;
    }
    if (cue?.wrongForms.map(normalize).contains(given) ?? false) {
      return ClozeVerdict.wrongForm;
    }
    if (slip(word, input, cue) != null) return ClozeVerdict.partOfSpeech;
    if (target.length >= 4 &&
        _distance(given, target) <= (target.length >= 8 ? 2 : 1)) {
      return ClozeVerdict.spelling;
    }
    return ClozeVerdict.unrelated;
  }

  /// Finds an adjective/adverb mix-up against the answer or a same-meaning
  /// word, e.g. `special` where `specially` fits.
  static PartOfSpeechSlip? slip(WordItem word, String input, [ClozeCue? cue]) {
    final given = normalize(input), target = normalize(word.answer);
    if (given.isEmpty || given.contains(' ') || given == target) return null;
    final fits = [target, ...?cue?.sameMeaning.map(normalize)];
    for (final fit in fits) {
      if (fit.contains(' ')) continue;
      if (adverbsOf(given).contains(fit)) {
        return PartOfSpeechSlip(fit, needsAdverb: true, isAnswer: fit == target);
      }
      if (adverbsOf(fit).contains(given)) {
        return PartOfSpeechSlip(fit,
            needsAdverb: false, isAnswer: fit == target);
      }
    }
    return null;
  }

  /// Regular adverbs formed from an adjective (special → specially).
  static Set<String> adverbsOf(String adjective) {
    final a = adjective;
    if (a.length < 3 || a.endsWith('ly')) return const {};
    return {
      '${a}ly',
      if (a.endsWith('y')) '${a.substring(0, a.length - 1)}ily',
      if (a.endsWith('le')) '${a.substring(0, a.length - 1)}y',
      if (a.endsWith('ic')) '${a}ally',
      if (a.endsWith('ue')) '${a.substring(0, a.length - 1)}ly',
      if (a.endsWith('ll')) '${a}y',
    };
  }

  static int _distance(String a, String b) {
    var previous = List<int>.generate(b.length + 1, (i) => i);
    for (var i = 1; i <= a.length; i++) {
      final current = [i, ...List<int>.filled(b.length, 0)];
      for (var j = 1; j <= b.length; j++) {
        current[j] = [
          previous[j] + 1,
          current[j - 1] + 1,
          previous[j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1)
        ].reduce((x, y) => x < y ? x : y);
      }
      previous = current;
    }
    return previous[b.length];
  }
}
