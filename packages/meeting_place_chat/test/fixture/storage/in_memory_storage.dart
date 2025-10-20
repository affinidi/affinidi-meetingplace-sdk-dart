import 'storage_interface.dart';

class InMemoryStorage implements IStorage {
  final Map<String, dynamic> records = {};

  @override
  Future<T?> get<T>(String key) async {
    final value = records[key];
    if (value is T) {
      return value;
    }
    return null;
  }

  @override
  Future<List<T>> getCollection<T>(String collectionId) async {
    return records.entries
        .where((r) => r.key.startsWith(collectionId))
        .toList()
        .cast<T>();
  }

  @override
  Future<void> put<T>(String key, T val) async {
    records[key] = val;
  }

  @override
  Future<void> remove(String key) async {
    records.remove(key);
    return Future.value();
  }
}
