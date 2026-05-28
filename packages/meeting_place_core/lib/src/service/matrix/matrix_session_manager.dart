// ignore_for_file: avoid_print

import 'package:matrix/matrix.dart' as matrix;

import 'matrix_auth_exception.dart';
import 'matrix_client.dart';
import 'matrix_client_cache.dart';
import 'matrix_config.dart';
import 'matrix_service_exception.dart';
import 'matrix_user_id_binding.dart';

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

  /// Configuration for Matrix client creation and homeserver details.
  final MatrixConfig _config;

  /// Cache of Matrix clients keyed by DID, storing the authenticated client
  /// for each logged-in user.
  final MatrixClientCache _clientCache;

  /// Exposes the homeserver URI from the configuration.
  Uri get homeserver => _config.homeserver;

  /// Logs in with [jwt] for the user identified by [did], returning the
  /// Matrix user ID. Creates a new client if none is cached for [did].
  ///
  /// On successful login, the authenticated client is cached for future use.
  /// If login fails (e.g. invalid/expired JWT), the client is removed from
  /// the cache and a [MatrixServiceException] is thrown.
  ///
  /// Parameters:
  /// - [jwt]: The Matrix JWT obtained from the control plane, used for login.
  /// - [did]: The DID of the user logging in, used to cache the client session.
  ///
  /// Returns: The Matrix user ID associated with the logged-in session.
  Future<String> loginWithJwt({
    required String jwt,
    required String did,
  }) async {
    try {
      final client = await _createClient(did: did);
      final response = await client.login(jwtLoginType, token: jwt);

      _clientCache.add(did: did, client: client);
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
  /// The caller is responsible for obtaining a fresh JWT and calling
  /// [loginWithJwt] before retrying.
  ///
  /// Throws [MatrixAuthException] when:
  /// - No session exists for [did].
  /// - The access token is missing (soft-logout).
  /// - The token is expiring soon and `refreshAccessToken` fails.
  ///
  /// Parameters:
  /// - [did]: The DID of the user for whom to retrieve the authenticated
  ///   client.
  ///
  /// Returns: The authenticated [matrix.Client] instance for the user.
  Future<matrix.Client> getAuthenticatedClient(String did) async {
    final client = _clientCache.get(did: did);

    if (client == null || client.accessToken == null) {
      throw const MatrixAuthException();
    }

    final expiresAt = client.accessTokenExpiresAt;
    final isExpiringSoon =
        expiresAt != null &&
        DateTime.now().isAfter(expiresAt.subtract(tokenGracePeriod));

    if (!isExpiringSoon) {
      return client;
    }

    try {
      print('demo: refreshAccessToken did=$did');
      await client.refreshAccessToken();
      return client;
    } catch (_) {
      _clientCache.remove(did: did);
      throw const MatrixAuthException();
    }
  }

  /// Clears all cached sessions, logging out from the Matrix homeserver.
  void dispose() {
    _clientCache.dispose();
  }

  /// Creates a new [matrix.Client] instance for the given [did], without
  /// logging in. The caller is responsible for calling [loginWithJwt] to
  /// authenticate the client and cache the session.
  ///
  /// Parameters:
  /// - [did]: The DID for which to create the Matrix client, used to derive
  ///   the Matrix user ID.
  ///
  /// Returns: A new instance of [matrix.Client] configured for the given DID.
  Future<matrix.Client> _createClient({required String did}) {
    return MatrixClient.init(
      config: _config,
      userScope: deriveUserId(did, _config.homeserver.host),
    );
  }

  /// Derives a Matrix user ID from a DID and the homeserver name, using a
  /// hash to ensure a consistent and unique mapping.
  ///
  /// The resulting user ID is in the format `@<hash>:<serverName>`,
  /// where `<hash>` is a SHA-256 hash of the concatenation of the DID and
  /// server name.
  ///
  /// This approach ensures that the same DID will always map to the same Matrix
  /// user ID on a given homeserver, without exposing the raw DID in the
  /// user ID.
  ///
  /// Parameters:
  /// - [did]: The DID to derive the user ID from.
  /// - [serverName]: The Matrix homeserver name, used as the domain in the
  ///   resulting user ID.
  ///
  /// Returns: A Matrix user ID derived from the DID and server name.
  String deriveUserId(String did, String serverName) {
    return deriveMatrixUserId(did, serverName);
  }
}
