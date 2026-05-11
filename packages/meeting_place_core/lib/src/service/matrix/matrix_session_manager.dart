import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:matrix/matrix.dart' as matrix;

import 'matrix_auth_exception.dart';
import 'matrix_client.dart';
import 'matrix_client_cache.dart';
import 'matrix_config.dart';
import 'matrix_service_exception.dart';

/// Manages the lifecycle of Matrix client sessions for individual DIDs.
///
/// Responsibilities:
/// - Creating and caching [matrix.Client] instances.
/// - Logging in with a JWT and storing the resulting session.
/// - Proactively refreshing access tokens before they expire.
///
/// This class has no dependency on the control plane. When a refresh fails,
/// it throws [MatrixAuthException] so the caller can obtain a fresh JWT and
/// call [loginWithJwt] again.
class MatrixSessionManager {
  MatrixSessionManager({
    required MatrixConfig config,
    MatrixClientCache? clientCache,
  }) : _config = config,
       _clientCache =
           clientCache ?? MatrixClientCache(homeserver: config.homeserver);

  /// The login type for JWT-based authentication with the Matrix homeserver.
  static const String jwtLoginType = 'org.matrix.login.jwt';

  /// How early before token expiry we proactively refresh, to avoid clock
  /// skew or latency causing a request to land on an expired token.
  static const Duration tokenGracePeriod = Duration(minutes: 2);

  final MatrixConfig _config;
  final MatrixClientCache _clientCache;

  Uri get homeserver => _config.homeserver;

  /// Logs in with [jwt] for the user identified by [did], returning the
  /// Matrix user ID. Creates a new client if none is cached for [did].
  Future<String> loginWithJwt({
    required String jwt,
    required String did,
  }) async {
    var client = _clientCache.get(did: did);

    if (client == null) {
      client = await _createClient(did: did);
      _clientCache.add(did: did, client: client);
    }

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

  /// Returns the cached, authenticated client for [did], refreshing the
  /// access token when it is within [tokenGracePeriod] of expiry.
  ///
  /// Throws [MatrixAuthException] when:
  /// - No session exists for [did].
  /// - The access token is missing (soft-logout).
  /// - The token is expiring soon and [refreshAccessToken] fails.
  ///
  /// The caller is responsible for obtaining a fresh JWT and calling
  /// [loginWithJwt] before retrying.
  Future<matrix.Client> getAuthenticatedClient(String did) async {
    final client = _clientCache.get(did: did);

    if (client == null || client.accessToken == null) {
      throw MatrixAuthException();
    }

    final expiresAt = client.accessTokenExpiresAt;
    final isExpiringSoon =
        expiresAt != null &&
        DateTime.now().isAfter(expiresAt.subtract(tokenGracePeriod));

    if (!isExpiringSoon) {
      return client;
    }

    try {
      await client.refreshAccessToken();
      return client;
    } catch (_) {
      _clientCache.remove(did: did);
      throw MatrixAuthException();
    }
  }

  void dispose() {
    _clientCache.dispose();
  }

  Future<matrix.Client> _createClient({required String did}) {
    return MatrixClient.init(
      config: _config,
      userScope: deriveUserId(did, _config.homeserver.host),
    );
  }

  String deriveUserId(String did, String serverName) {
    return '@${sha256.convert(utf8.encode('$did|$serverName')).toString()}:$serverName';
  }
}
