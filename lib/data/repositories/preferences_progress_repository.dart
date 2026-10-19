import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_voca/domain/repositories/progress_repository.dart';

class PreferencesProgressRepository implements ProgressRepository {
  final SharedPreferences preferences;
  PreferencesProgressRepository(this.preferences);
  static const storageKey = 'daily_english_v1';
  @override
  Map<String, dynamic>? load() {
    final raw = preferences.getString(storageKey);
    return raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;
  }

  @override
  Future<void> save(Map<String, dynamic> snapshot) async {
    if (!await preferences.setString(storageKey, jsonEncode(snapshot))) {
      throw StateError('Progress save failed');
    }
  }
}
