import 'package:flutter/foundation.dart';
import 'package:edu_voca/domain/models/word_item.dart';
import 'package:edu_voca/domain/repositories/vocabulary_repository.dart';

class VocabularyViewModel extends ChangeNotifier {
  final VocabularyRepository repository;
  String query = '';
  bool spokenOnly = false;
  bool phrasesOnly = false;
  VocabularyViewModel(this.repository);
  List<WordItem> get matches => repository.words
      .where((word) =>
          (!spokenOnly || word.spokenCore) &&
          (!phrasesOnly || word.isPhrase) &&
          (word.headword.toLowerCase().contains(query) ||
              (word.meaning ?? word.translation).contains(query)))
      .toList();
  void search(String value) {
    query = value.trim().toLowerCase();
    notifyListeners();
  }

  void filterSpoken(bool value) {
    spokenOnly = value;
    if (value) phrasesOnly = false;
    notifyListeners();
  }

  void filterPhrases(bool value) {
    phrasesOnly = value;
    if (value) spokenOnly = false;
    notifyListeners();
  }
}
