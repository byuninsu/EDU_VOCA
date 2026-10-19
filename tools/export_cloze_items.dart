// Writes every practice blank as JSON for tools/build_cloze_cues.py.
// Usage: dart run tools/export_cloze_items.dart <output.json>
import 'dart:convert';
import 'dart:io';
import 'package:edu_voca/data/repositories/local_vocabulary_repository.dart';

void main(List<String> args) {
  final repository = LocalVocabularyRepository();
  final items = [
    for (final word in repository.byId.values)
      {
        'id': word.id,
        'headword': word.headword,
        'answer': word.answer,
        'sentence': word.sentence,
        'translation': word.translation,
        'meaning': word.meaning,
        'partsOfSpeech': word.partsOfSpeech,
      }
  ];
  File(args.single).writeAsStringSync(jsonEncode(items));
  stdout.writeln('${items.length} items');
}
