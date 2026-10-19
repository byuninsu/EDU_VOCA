import 'package:flutter/foundation.dart';
import 'package:edu_voca/domain/models/scenario.dart';
import 'package:edu_voca/domain/models/writing_feedback.dart';
import 'package:edu_voca/domain/services/writing_evaluator.dart';
import 'package:edu_voca/features/learning/view_models/learning_view_model.dart';

/// A role-play conversation, one turn at a time. Retry is unlimited until a
/// reply is good or very good, or the learner chooses to see the example.
class WritingViewModel extends ChangeNotifier {
  final LearningViewModel learning;
  final Scenario scenario;
  final WritingEvaluator evaluator;
  int turn;
  WritingFeedback? feedback;
  bool evaluating = false, revealed = false, saved = false;
  int attempts = 0;
  String? error;

  /// Settled replies of earlier turns, shown as the conversation so far.
  final List<String> replies = [];
  String _answer = '';
  bool _weak = false;
  int _revision = 0;
  bool _disposed = false;
  WritingViewModel(
      {required this.learning,
      required this.scenario,
      this.evaluator = const OfflineWritingEvaluator(),
      this.turn = 0}) {
    // Starting later (from a review) shows the earlier model replies.
    replies.addAll(scenario.turns.take(turn).map((t) => t.example));
  }

  DialogueTurn get current => scenario.turns[turn];
  bool get isLastTurn => turn == scenario.turns.length - 1;

  /// The current turn is settled and the conversation can move on.
  bool get done =>
      revealed || (feedback != null && feedback!.grade != WritingGrade.retry);

  /// English sentence to read aloud once the reply is settled.
  String? get lineToSpeak {
    if (revealed) return current.example;
    if (!done) return null;
    final better = feedback!.betterAnswer;
    return better.isEmpty ? _answer : better;
  }

  Future<void> evaluate(String answer) async {
    if (evaluating || done) return;
    if (answer.trim().isEmpty) {
      error = '먼저 영어로 문장을 작성해 주세요.';
      notifyListeners();
      return;
    }
    final revision = ++_revision;
    _answer = answer.trim();
    error = null;
    evaluating = true;
    notifyListeners();
    final WritingFeedback result;
    try {
      result = await evaluator.evaluate(scenario, turn, _answer);
    } catch (_) {
      if (_disposed || revision != _revision) return;
      evaluating = false;
      error = '평가하지 못했어요.\n잠시 후 다시 시도해 주세요.';
      notifyListeners();
      return;
    }
    if (_disposed || revision != _revision) return;
    evaluating = false;
    feedback = result;
    attempts++;
    if (result.grade == WritingGrade.good) _save();
    if (result.grade == WritingGrade.veryGood && isLastTurn && !_weak) {
      learning.finishWriting(scenario.id);
    }
    notifyListeners();
  }

  /// Shows the model answer and keeps this conversation for review.
  void reveal(String answer) {
    if (done || evaluating) return;
    _answer = answer.trim();
    revealed = true;
    _save();
    notifyListeners();
  }

  /// Moves to the next exchange once this one is settled.
  void advance() {
    if (!done || isLastTurn) return;
    replies.add(revealed ? current.example : (lineToSpeak ?? _answer));
    turn++;
    _resetTurn();
    notifyListeners();
  }

  /// Starts a fresh attempt at the current exchange.
  void tryAgain() {
    _resetTurn();
    notifyListeners();
  }

  void _resetTurn() {
    ++_revision;
    feedback = null;
    revealed = false;
    saved = false;
    attempts = 0;
    evaluating = false;
    error = null;
  }

  void _save() {
    _weak = true;
    learning.saveWriting(scenario, Scenario.reviewValue(turn, _answer));
    saved = true;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
