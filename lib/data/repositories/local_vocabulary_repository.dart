import 'package:edu_voca/domain/models/word_item.dart';
import 'package:edu_voca/domain/models/scenario.dart';
import 'package:edu_voca/domain/repositories/vocabulary_repository.dart';
import 'package:edu_voca/data/local/ngsl_data.dart';
import 'package:edu_voca/data/local/oxford_levels.dart';
import 'package:edu_voca/data/local/word_hints.dart';
import 'package:edu_voca/data/local/cloze_examples.dart';
import 'package:edu_voca/data/local/phrases.dart';
import 'package:edu_voca/data/local/cloze_cues.dart' as cues;
import 'package:edu_voca/domain/models/cloze_cue.dart';
import '../local/legacy_words.dart' as legacy;
import '../local/scenarios.dart' as writing;

class LocalVocabularyRepository implements VocabularyRepository {
  LocalVocabularyRepository() {
    words = List.unmodifiable([
      ...ngslVocabulary.map((entry) {
        final classified = WordItem.withCefr(entry, oxfordLevels[entry.id],
            partsOfSpeech: wordPartsOfSpeech[entry.id]);
        final examples = legacy.words.where((w) =>
            w.answer.toLowerCase() == entry.id ||
            (entry.id == 'sound' && w.id == 'sounds'));
        return examples.isEmpty
            ? WordItem.withCloze(classified, clozeExamples[entry.id]!)
            : WordItem.withExample(classified, examples.first);
      }),
      ...phrases.map((word) => WordItem.withCefr(word, word.cefr,
          partsOfSpeech: wordPartsOfSpeech[word.id]))
    ]);
    byId = Map.unmodifiable({
      for (final w in legacy.words.where((w) => w.id != 'takeforgranted'))
        w.id: WordItem.withCefr(w, oxfordLevels[w.headword.toLowerCase()],
            partsOfSpeech: wordPartsOfSpeech[w.id] ??
                wordPartsOfSpeech[w.headword.toLowerCase()]),
      for (final w in words) w.id: w,
    });
  }
  @override
  late final List<WordItem> words;
  @override
  late final Map<String, WordItem> byId;
  @override
  List<Scenario> get scenarios => writing.scenarios;
  @override
  Map<String, ClozeCue> get clozeCues => cues.clozeCues;
}
