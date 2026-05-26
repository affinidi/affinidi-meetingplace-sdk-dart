import 'package:meeting_place_core/meeting_place_core.dart';

class MatrixUserIdCache {
  MatrixUserIdCache({required String serverName}) : _serverName = serverName;

  final String _serverName;
  final Map<String, String> _cache = {};

  void register(String did) =>
      _cache[deriveMatrixUserId(did, _serverName)] = did;

  void registerAll(Iterable<String> dids) {
    for (final did in dids) {
      register(did);
    }
  }

  String? resolve(String matrixUserId) => _cache[matrixUserId];
}
