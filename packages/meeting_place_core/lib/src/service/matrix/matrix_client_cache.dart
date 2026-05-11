import 'package:matrix/matrix.dart' as matrix;
import 'matrix_client.dart';

class MatrixClientCache {
  MatrixClientCache({required this.homeserver});

  final Uri homeserver;
  final Map<String, matrix.Client> _clientCache = {};

  matrix.Client add({required String did, required matrix.Client client}) {
    final cacheKey = _getCacheKey(did: did);
    return _clientCache.putIfAbsent(cacheKey, () => client);
  }

  matrix.Client? get({required String did}) {
    final cacheKey = _getCacheKey(did: did);
    return _clientCache[cacheKey];
  }

  void remove({required String did}) {
    final cacheKey = _getCacheKey(did: did);
    _clientCache.remove(cacheKey);
  }

  void dispose() {
    _clientCache.clear();
  }

  String _getCacheKey({required String did}) {
    return '$did._${homeserver.toString()}';
  }
}
