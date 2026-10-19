/// One complete bilingual example with exactly one target-token blank.
class ClozeExample {
  final String sentence, answer, translation, credit;
  final String? translationFocus;
  const ClozeExample(
      {required this.sentence,
      required this.answer,
      required this.translation,
      required this.credit,
      this.translationFocus});
}
