enum WritingGrade { veryGood, good, retry }

/// One evaluation of a learner's role-play reply.
class WritingFeedback {
  final WritingGrade grade;

  /// Short Korean coaching comment.
  final String comment;

  /// A very good English reply close to the learner's wording; empty on retry.
  final String betterAnswer;

  /// True when the simple on-device check was used instead of AI.
  final bool offline;
  const WritingFeedback(this.grade, this.comment,
      {this.betterAnswer = '', this.offline = false});
}
