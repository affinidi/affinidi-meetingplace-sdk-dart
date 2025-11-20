import 'dart:typed_data';

import 'package:meeting_place_core/meeting_place_core.dart';
import '../storage.dart';

class KeyRepositoryImpl implements KeyRepository {
  KeyRepositoryImpl({required InMemoryStorage storage}) : _storage = storage;

  static final String _didPrefix = 'did_';
  static final String _indexPrefix = 'index_';
  static final String _keyPairIndex = 'keyPair_';

  final InMemoryStorage _storage;

  @override
  Future<String?> getKeyIdByDid({required String did}) {
    return _storage.get('$_didPrefix$did');
  }

  @override
  Future<int> getLastAccountIndex() async {
    return (await _storage.get<int?>(_indexPrefix)) ?? 1;
  }

  @override
  Future<void> saveKeyIdForDid({
    required String keyId,
    required String did,
  }) async {
    await _storage.put('$_didPrefix$did', keyId);
  }

  @override
  Future<void> setLastAccountIndex(int index) {
    return _storage.put(_indexPrefix, index);
  }

  @override
  Future<void> saveKeyPair({
    required Uint8List privateKeyBytes,
    required Uint8List publicKeyBytes,
    required String did,
  }) {
    return _storage.put('$_keyPairIndex$did', {
      'privateKeyBytes': privateKeyBytes,
      'publicKeyBytes': publicKeyBytes,
    });
  }

  @override
  Future<KeyPair?> getKeyPair(String did) async {
    final keyPair =
        await _storage.get<Map<String, Uint8List>>('$_keyPairIndex$did');
    if (keyPair == null) return null;

    return KeyPair(
      publicKeyBytes: keyPair['publicKeyBytes']!,
      privateKeyBytes: keyPair['privateKeyBytes']!,
    );
  }
}
