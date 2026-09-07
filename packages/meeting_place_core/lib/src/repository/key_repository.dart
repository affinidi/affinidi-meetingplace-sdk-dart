/// Persists key/DID material used to derive and look up local identity keys.
///
/// Implementations back the SDK's key management with durable storage (for
/// example a Drift/SQLite database or secure storage) so key associations
/// survive across app restarts.
abstract interface class KeyRepository {
  /// Returns the highest account index used so far, for deriving the next
  /// key.
  Future<int> getLastAccountIndex();

  /// Persists [index] as the last used account index.
  Future<void> setLastAccountIndex(int index);

  /// Associates [keyId] with [did] so it can later be looked up by [did].
  Future<void> saveKeyIdForDid({required String keyId, required String did});

  /// Finds the key id previously saved for [did].
  ///
  /// Returns `null` if no key id has been saved for that DID.
  Future<String?> findKeyIdByDid({required String did});
}
