class InMemoryStorage {
  final Map<String, dynamic> records = {};

  Future<T?> get<T>(String key) async {
    final value = records[key];
    if (value is T) {
      return value;
    }
    return null;
  }

  Future<List<T>> getCollection<T>(String collectionId) async {
    return records.entries
        .where((r) => r.key.startsWith(collectionId))
        .toList()
        .cast<T>();
  }

  Future<void> put<T>(String key, T val) async {
    records[key] = val;
  }

  Future<void> remove(String key) async {
    records.remove(key);
    return Future.value();
  }
}
