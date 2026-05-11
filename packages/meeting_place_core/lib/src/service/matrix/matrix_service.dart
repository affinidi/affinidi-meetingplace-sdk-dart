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

  /// The login type for JWT-based authentication with the Matrix homeserver.
  static const String jwtLoginType = 'org.matrix.login.jwt';

  final MatrixConfig _config;
  final MatrixClientCache _clientCache;

  Uri get homeserver => _config.homeserver;

  Future<String> loginWithJwt({
    required String jwt,
    required String did,
  }) async {
    final client = await _createClient(did: did);

    _clientCache.add(did: did, client: client);

    try {
      final response = await client.login(jwtLoginType, token: jwt);
      return response.userId;
    } catch (error, stackTrace) {
      _clientCache.remove(did: did);
      Error.throwWithStackTrace(
        MatrixServiceException.loginFailed(innerException: error),
        stackTrace,
      );
    }
  }

  Future<String> createRoom({
    required String did,
    List<String>? inviteUsers,
  }) async {
    final client = await _getClientForUser(did: did);
    return client.createRoom(
      invite: inviteUsers
          ?.map((inviteDid) => _deriveUserId(inviteDid, homeserver.host))
          .toList(),
    );
  }

  Future<void> joinRoom(String roomId, {required String did}) async {
    final client = await _getClientForUser(did: did);
    await client.joinRoom(roomId);
  }

  void dispose() {
    _clientCache.dispose();
  }

  Future<matrix.Client> _getClientForUser({required String did}) async {
    final cached = _clientCache.get(did: did);
    if (cached != null) {
      return cached;
    }

    final client = await _createClient(did: did);

    _clientCache.add(did: did, client: client);
    return client;
  }

  Future<matrix.Client> _createClient({required String did}) {
    return MatrixClient.init(
      config: _config,
      userScope: _deriveUserId(did, _config.homeserver.host),
    );
  }

  String _deriveUserId(String did, String serverName) {
    return '''@${sha256.convert(utf8.encode('$did|$serverName')).toString()}:$serverName''';
  }
}
