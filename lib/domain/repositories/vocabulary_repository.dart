import 'package:edu_voca/domain/models/word_item.dart';
import 'package:edu_voca/domain/models/scenario.dart';
import 'package:edu_voca/domain/models/cloze_cue.dart';

abstract interface class VocabularyRepository {
  List<WordItem> get words;
  Map<String, WordItem> get byId;
  List<Scenario> get scenarios;

  /// Prepared same-meaning words and wrong forms by word id.
  Map<String, ClozeCue> get clozeCues;
}
