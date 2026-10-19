import 'package:flutter/material.dart';
import 'dart:async';
import 'data/repositories/firebase_auth_repository.dart';
import 'features/account/view_models/account_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_voca/app/app.dart';
import 'package:edu_voca/features/learning/view_models/learning_view_model.dart';
import 'package:edu_voca/data/repositories/local_vocabulary_repository.dart';
import 'package:edu_voca/data/repositories/preferences_progress_repository.dart';
import 'package:edu_voca/data/repositories/memory_progress_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (_) {}
  final state = LearningViewModel(
    repository: prefs == null
        ? MemoryProgressRepository()
        : PreferencesProgressRepository(prefs),
    vocabulary: LocalVocabularyRepository(),
  );
  if (prefs == null) {
    state.storageError = '저장소 연결 실패: 이번 기록은 앱을 종료하면 사라질 수 있어요.';
  }
  final account = AccountViewModel(FirebaseAuthRepository());
  runApp(DailyEnglishApp(state: state, account: account));
  unawaited(account.initialize());
}
