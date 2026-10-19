import 'package:flutter_test/flutter_test.dart';
import 'package:edu_voca/data/repositories/local_vocabulary_repository.dart';
import 'package:edu_voca/data/repositories/memory_progress_repository.dart';
import 'package:edu_voca/data/repositories/preferences_progress_repository.dart';
import 'package:edu_voca/features/learning/view_models/learning_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_voca/domain/models/learning_progress.dart';
export 'package:edu_voca/domain/models/word_item.dart';
export 'package:edu_voca/domain/models/scenario.dart';
export 'package:edu_voca/domain/models/exercise.dart';
export 'package:edu_voca/domain/models/review_entry.dart';
export 'package:edu_voca/features/learning/view_models/learning_view_model.dart';

final vocabulary = LocalVocabularyRepository();
final playableWords = vocabulary.words;
final wordsById = vocabulary.byId;
final scenarios = vocabulary.scenarios;
LearningViewModel createLearning(
    {SharedPreferences? preferences, int completed = 0}) {
  final repository = preferences == null
      ? MemoryProgressRepository(
          initial: (LearningProgress()..completed = completed).toJson())
      : PreferencesProgressRepository(preferences);
  return LearningViewModel(repository: repository, vocabulary: vocabulary);
}


/// Answers are checked automatically at full length; the keyboard's done key
/// submits anything else (for example a wrong or shorter answer).
Future<void> submitAnswer(WidgetTester tester) async {
  if (tester.testTextInput.hasAnyClients) {
    await tester.testTextInput.receiveAction(TextInputAction.done);
  }
  await tester.pumpAndSettle();
}
