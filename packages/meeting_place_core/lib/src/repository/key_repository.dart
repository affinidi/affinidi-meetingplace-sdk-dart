abstract interface class KeyRepository {
  Future<int> getLastAccountIndex();

  Future<void> setLastAccountIndex(int index);

  Future<void> saveKeyIdForDid({required String keyId, required String did});

  Future<String?> getKeyIdByDid({required String did});
}
