/// One exchange: the other person speaks, the learner answers in English.
class DialogueTurn {
  final String partner, prompt, example, tip;

  /// Other very good replies, used by the offline check and as AI context.
  final List<String> alternatives;
  const DialogueTurn(this.partner, this.prompt, this.example, this.tip,
      {this.alternatives = const []});
}

/// A role-play situation practised as a continuing conversation.
class Scenario {
  final String id, emoji, title, subtitle;
  final List<DialogueTurn> turns;
  const Scenario(this.id, this.emoji, this.title, this.subtitle, this.turns);

  /// Saved review text: the turn number and the learner's reply.
  static String reviewValue(int turn, String answer) => '$turn\t$answer';

  /// Older saves hold only the reply of the first turn.
  static (int, String) parseReview(String value) {
    final tab = value.indexOf('\t');
    final turn = tab < 0 ? null : int.tryParse(value.substring(0, tab));
    return turn == null ? (0, value) : (turn, value.substring(tab + 1));
  }
}
