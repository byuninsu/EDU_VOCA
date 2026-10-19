import 'dart:convert';
import 'package:edu_voca/domain/repositories/progress_repository.dart';

class MemoryProgressRepository implements ProgressRepository {
  String? _snapshot;
  MemoryProgressRepository({Map<String, dynamic>? initial})
      : _snapshot = initial == null ? null : jsonEncode(initial);
  @override
  Map<String, dynamic>? load() =>
      _snapshot == null ? null : jsonDecode(_snapshot!) as Map<String, dynamic>;
  @override
  Future<void> save(Map<String, dynamic> snapshot) async {
    _snapshot = jsonEncode(snapshot);
  }
}
