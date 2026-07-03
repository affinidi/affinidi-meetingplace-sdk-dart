import 'package:meeting_place_core/meeting_place_core.dart';

import '../storage/storage.dart';

class KeyRepositoryImpl implements KeyRepository {
  KeyRepositoryImpl({required Storage storage}) : _storage = storage;

  static final String _didPrefix = 'did_';
  static final String _indexPrefix = 'index_';

  final Storage _storage;

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
    final indexKey = _indexPrefix;
    return _storage.put(indexKey, index);
  }
}
