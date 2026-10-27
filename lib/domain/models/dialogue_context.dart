/// The opening turn of a bilingual cloze conversation. The existing WordItem
/// supplies the reply, translation and answer so grading/reviews stay stable.
class DialogueContext {
  final String situation, english, korean;
  const DialogueContext(this.situation, this.english, this.korean);
}
