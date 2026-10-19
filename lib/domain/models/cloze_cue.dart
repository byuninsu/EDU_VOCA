/// Prepared answers for one blank, generated offline (tools/build_cloze_cues.py).
class ClozeCue {
  /// Other words that fit the blank with the same meaning.
  final List<String> sameMeaning;

  /// The target word in forms that do not fit this sentence.
  final List<String> wrongForms;
  const ClozeCue({this.sameMeaning = const [], this.wrongForms = const []});
}
