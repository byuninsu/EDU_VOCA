abstract interface class ProgressRepository {
  Map<String, dynamic>? load();
  Future<void> save(Map<String, dynamic> snapshot);
}
