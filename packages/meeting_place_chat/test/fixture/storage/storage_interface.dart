abstract interface class IStorage {
  Future<T?> get<T>(String key);
  Future<void> put<T>(String key, T val);
  Future<List<T>> getCollection<T>(String collectionId);
  Future<void> remove(String key);
}
