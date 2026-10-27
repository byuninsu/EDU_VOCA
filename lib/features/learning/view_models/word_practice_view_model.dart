import 'package:flutter/foundation.dart';
import 'package:edu_voca/domain/models/exercise.dart';
import 'package:edu_voca/domain/models/learning_progress.dart';
import 'learning_view_model.dart';
import 'package:edu_voca/domain/models/word_item.dart';
import 'package:edu_voca/domain/services/cloze_judge.dart';
import 'package:edu_voca/data/local/dialogue_contexts.dart';
import 'package:edu_voca/domain/models/dialogue_context.dart';
import 'package:edu_voca/domain/models/dialogue_cast.dart';

/// Colour family of the guidance line under the sentence.
enum GuideTone { idle, hint, close, wrong }

enum EarlyCheck { none, now, afterPause }

class WordPracticeViewModel extends ChangeNotifier {
  static const idleGuide = '빈칸을 눌러 입력하세요.';
  final LearningViewModel learning;
  List<Exercise> _exercises;
  bool countsToday;
  int index = 0, hits = 0;
  bool? correct;
  bool finished = false;
  String guide = idleGuide;
  GuideTone tone = GuideTone.idle;
  bool hintVisible = false, usedHint = false;
  bool solvedWithHint = false;
  String get firstLetter => _exercises[index].word.answer.trim()[0];

  void showHint() {
    if (correct != null || finished || hintVisible) return;
    hintVisible = true;
    usedHint = true;
    _guide("'$firstLetter'로 시작하는 표현이에요.", GuideTone.hint);
    notifyListeners();
  }

  WordPracticeViewModel(
      {required this.learning,
      required List<Exercise> exercises,
      required this.countsToday})
      : _exercises = List.unmodifiable(exercises) {
    if (exercises.isEmpty) {
      throw ArgumentError.value(exercises, 'exercises', 'Must not be empty');
    }
  }
  List<Exercise> get exercises => _exercises;
  DialogueCast _cast = DialogueCast.random();
  DialogueCast get cast => _cast;
  DialogueContext get dialogue => dialogueContextFor(_exercises[index].word);
  String get completeDialogue =>
      '${dialogue.english}\n${_exercises[index].word.complete}';

  void _guide(String text, GuideTone value) {
    guide = text;
    tone = value;
  }

  /// Experience change from the latest graded answer.
  XpResult xpResult = XpResult.none;

  void _reset() {
    xpResult = XpResult.none;
    correct = null;
    _guide(idleGuide, GuideTone.idle);
    hintVisible = usedHint = solvedWithHint = false;
  }

  void submit(String answer) {
    if (correct != null || finished) return;
    final word = _exercises[index].word;
    if (answer.trim().isEmpty) {
      _guide('빈칸에 들어갈 표현을 입력해 주세요.', GuideTone.wrong);
    } else if (normalize(answer) == normalize(word.answer)) {
      solvedWithHint = usedHint;
      grade(!usedHint);
      return;
    } else {
      final cue = learning.vocabulary.clozeCues[word.id];
      _apply(LocalClozeCheck.judge(word, answer, cue), answer.trim(),
          LocalClozeCheck.slip(word, answer, cue));
    }
    notifyListeners();
  }

  /// How soon a guess of a different length than the answer is judged:
  /// prepared cues right away, or after a pause while the letters could still
  /// grow into another cue (`special` on the way to `specially`).
  EarlyCheck earlyCheck(String answer) {
    final word = _exercises[index].word;
    final given = normalize(answer);
    if (given.isEmpty || normalize(word.answer).startsWith(given)) {
      return EarlyCheck.none;
    }
    final cue = learning.vocabulary.clozeCues[word.id];
    final verdict = LocalClozeCheck.judge(word, answer, cue);
    if (verdict == ClozeVerdict.unrelated || verdict == ClozeVerdict.spelling) {
      return EarlyCheck.none;
    }
    final longer = [...?cue?.sameMeaning, ...?cue?.wrongForms]
        .map(normalize)
        .any((candidate) => candidate != given && candidate.startsWith(given));
    return longer ? EarlyCheck.afterPause : EarlyCheck.now;
  }

  /// A same-meaning word earns the first letter as a free hint.
  void _apply(ClozeVerdict verdict, String input, PartOfSpeechSlip? slip) {
    switch (verdict) {
      case ClozeVerdict.sameMeaning:
        hintVisible = true;
        _guide("'$input'도 뜻은 같아요!\n'$firstLetter'로 시작하는 단어도 생각해 보세요.",
            GuideTone.hint);
      case ClozeVerdict.wrongForm:
        _guide('단어는 맞아요!\n문장에 맞는 형태로 바꿔 보세요.', GuideTone.close);
      case ClozeVerdict.partOfSpeech:
        final (have, need) = slip!.needsAdverb ? ('형용사', '부사') : ('부사', '형용사');
        _guide(
            slip.isAnswer
                ? '단어는 맞아요!\n하지만 $have라서 이 자리에는 안 맞아요.\n'
                    '여기는 $need 자리예요.\n형태를 바꿔 보세요.'
                : "'$input'도 뜻은 비슷해요!\n하지만 $have라서 이 자리에는 안 맞아요.\n"
                    "여기는 $need 자리라 '${slip.fix}'처럼 써야 해요.\n"
                    '다른 단어도 생각해 보세요.',
            GuideTone.hint);
      case ClozeVerdict.spelling:
        _guide('거의 다 왔어요!\n철자를 다시 확인해 보세요.', GuideTone.close);
      case ClozeVerdict.unrelated:
        _guide('조금 더 생각해 보세요.\n계속 도전할 수 있어요!', GuideTone.wrong);
    }
  }

  void reveal() => grade(false);
  void grade(bool result) {
    if (correct != null || finished) return;
    // Mark first to make duplicate submissions/reentrant callbacks harmless.
    correct = result;
    if (result) hits++;
    xpResult =
        learning.answer(_exercises[index], result, countsToday: countsToday);
    notifyListeners();
  }

  void next() {
    if (correct == null || finished) return;
    if (index == _exercises.length - 1) {
      finished = true;
    } else {
      index++;
      _cast = DialogueCast.random(previous: _cast);
      _reset();
    }
    notifyListeners();
  }

  void continuePractice() {
    final session = learning.makeSession();
    if (session.isEmpty) return;
    _exercises = List.unmodifiable(session);
    countsToday = true;
    index = 0;
    _cast = DialogueCast.random(previous: _cast);
    hits = 0;
    finished = false;
    _reset();
    notifyListeners();
  }
}
