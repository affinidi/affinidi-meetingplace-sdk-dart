import 'package:matrix/matrix.dart' as matrix;
import 'matrix_client.dart';
import 'matrix_client_cache.dart';
import 'matrix_service_exception.dart';

class MatrixService {
  MatrixService({
    required Uri this.homeserver,
    required Future<dynamic> Function(String) databaseProvider,
    MatrixClientCache? clientCache,
  }) : _databaseProvider = databaseProvider,
       _clientCache = clientCache ?? MatrixClientCache(homeserver: homeserver);

  static const String jwtLoginType = 'org.matrix.login.jwt';

  final Uri homeserver;
  final Future<dynamic> Function(String) _databaseProvider;
  final MatrixClientCache _clientCache;

  Future<String> loginWithJwt({
    required String jwt,
    required String userScope,
  }) async {
    final client = await _getClientForUser(userScope: userScope);

    try {
      final response = await client.login(jwtLoginType, token: jwt);
      return response.userId;
    } catch (error, stackTrace) {
      _clientCache.remove(userScope: userScope);
      Error.throwWithStackTrace(
        MatrixServiceException.loginFailed(innerException: error),
        stackTrace,
      );
    }
  }

  void dispose() {
    _clientCache.dispose();
  }

  Future<matrix.Client> _getClientForUser({required String userScope}) async {
    final cached = _clientCache.get(userScope: userScope);
    if (cached != null) {
      return cached;
    }

    final client = await _createClient(
      userScope: userScope,
      databaseProvider: _databaseProvider,
    );

    _clientCache.add(userScope: userScope, client: client);
    return client;
  }

  Future<matrix.Client> _createClient({
    required String userScope,
    required Future<dynamic> Function(String) databaseProvider,
  }) {
    return MatrixClient.init(
      homeserver: homeserver,
      userScope: userScope,
      databaseProvider: databaseProvider,
    );
  }
}
