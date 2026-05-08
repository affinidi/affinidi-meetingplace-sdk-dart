import 'package:matrix/matrix.dart' as matrix;
import 'matrix_client.dart';

class MatrixClientCache {
  MatrixClientCache({required this.homeserver});

  final Uri homeserver;
  final Map<String, matrix.Client> _clientCache = {};

  matrix.Client add({
    required String userScope,
    required matrix.Client client,
  }) {
    final cacheKey = _getCacheKey(userScope: userScope);
    return _clientCache.putIfAbsent(cacheKey, () => client);
  }

  matrix.Client? get({required String userScope}) {
    final cacheKey = _getCacheKey(userScope: userScope);
    return _clientCache[cacheKey];
  }

  void remove({required String userScope}) {
    final cacheKey = _getCacheKey(userScope: userScope);
    _clientCache.remove(cacheKey);
  }

  void dispose() {
    _clientCache.clear();
  }

  String _getCacheKey({required String userScope}) {
    return userScope.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_').toLowerCase();
  }
}
