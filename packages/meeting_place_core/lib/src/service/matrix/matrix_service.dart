import 'package:matrix/matrix.dart' as matrix;
import 'matrix_client.dart';
import 'matrix_client_cache.dart';
import 'matrix_config.dart';
import 'matrix_service_exception.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class MatrixService {
  MatrixService({required MatrixConfig config, MatrixClientCache? clientCache})
    : _config = config,
      _clientCache =
          clientCache ?? MatrixClientCache(homeserver: config.homeserver);

  static const String jwtLoginType = 'org.matrix.login.jwt';

  final MatrixConfig _config;
  final MatrixClientCache _clientCache;

  Uri get homeserver => _config.homeserver;

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

  Future<String> createRoom({
    required String userScope,
    List<String>? inviteUsers,
  }) async {
    final client = await _getClientForUser(userScope: userScope);
    return client.createRoom(invite: inviteUsers);
  }

  Future<String> deriveUserId(String did, String serverName) async {
    return '@${sha256.convert(utf8.encode('$did|$serverName')).toString()}:$serverName';
  }

  void dispose() {
    _clientCache.dispose();
  }

  Future<matrix.Client> _getClientForUser({required String userScope}) async {
    final cached = _clientCache.get(userScope: userScope);
    if (cached != null) {
      return cached;
    }

    final client = await _createClient(userScope: userScope);

    _clientCache.add(userScope: userScope, client: client);
    return client;
  }

  Future<matrix.Client> _createClient({required String userScope}) {
    return MatrixClient.init(config: _config, userScope: userScope);
  }
}
