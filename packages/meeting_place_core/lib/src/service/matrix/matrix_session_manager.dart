import 'package:matrix/matrix.dart' as matrix;

import '../../loggers/meeting_place_core_sdk_logger.dart';
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
/// This class has no dependency on the control plane. When no usable
/// session exists, [getAuthenticatedClient] returns `null` so the caller
/// can obtain a fresh JWT and call [loginWithJwt] again.
class MatrixSessionManager {
  MatrixSessionManager({
    required MatrixConfig config,
    required MeetingPlaceCoreSDKLogger logger,
    MatrixClientCache? clientCache,
  }) : _config = config,
       _logger = logger,
       _clientCache =
           clientCache ?? MatrixClientCache(homeserver: config.homeserver);

  /// The login type for JWT-based authentication with the Matrix homeserver.
  static const String jwtLoginType = 'org.matrix.login.jwt';

  /// How early before token expiry we proactively refresh, to avoid clock
  /// skew or latency causing a request to land on an expired token.
  static const Duration tokenGracePeriod = Duration(minutes: 2);

  /// Configuration for Matrix client creation and homeserver details.
  final MatrixConfig _config;

  /// Cache of in-flight and resolved Matrix login Futures keyed by DID.
  final MatrixClientCache _clientCache;

  /// Logger for session manager operations and errors.
  final MeetingPlaceCoreSDKLogger _logger;

  /// In-flight login attempts keyed by DID.
  final Map<String, Future<matrix.Client>> _inFlightLogins = {};

  static const _logKey = 'MatrixSessionManager';

  /// Exposes the homeserver URI from the configuration.
  Uri get homeserver => _config.homeserver;

  /// Logs in with [jwt] for the user identified by [did], returning the
  /// Matrix user ID.
  ///
  /// Caching behaviour:
  /// - If a cached session for [did] is already authenticated and its access
  ///   token is not within [tokenGracePeriod] of expiry, the cached client's
  ///   user ID is returned without contacting the homeserver.
  /// - If a login for [did] is already in flight, this call awaits the same
  ///   Future rather than starting a second login.
  /// - Otherwise a new client is created and logged in. The in-flight Future
  ///   is published to the cache before awaiting, so concurrent callers and
  ///   readers via [getAuthenticatedClient] observe the same session.
  ///
  /// On login failure the cache entry is evicted and a [MatrixServiceException]
  /// is thrown.
  Future<String> loginWithJwt({
    required String jwt,
    required String did,
  }) async {
    final loginFuture = _inFlightLogins.putIfAbsent(did, () async {
      final cached = _clientCache.get(did: did);
      matrix.Client? existingClient;
      if (cached != null) {
        try {
          existingClient = await cached;
          if (_isTokenFresh(existingClient)) {
            return existingClient;
          }
        } catch (_) {
          // Previous login attempt errored; fall through and retry with a
          // fresh client.
          existingClient = null;
        }
      }

      _logger.info(
        'Logging in to Matrix homeserver with DID $did',
        name: _logKey,
      );

      final attempt = _login(did: did, jwt: jwt, existing: existingClient);
      _clientCache.add(did: did, future: attempt);

      try {
        return await attempt;
      } catch (error, stackTrace) {
        _clientCache.remove(did: did);
        Error.throwWithStackTrace(
          MatrixServiceException.loginFailed(innerException: error),
          stackTrace,
        );
      }
    });

    try {
      final client = await loginFuture;
      return client.userID!;
    } finally {
      if (identical(_inFlightLogins[did], loginFuture)) {
        await _inFlightLogins.remove(did);
      }
    }
  }

  /// Returns the cached, authenticated client for [did], refreshing the
  /// access token when it is within [tokenGracePeriod] of expiry.
  ///
  /// Returns `null` when no usable session exists (no cache entry, prior
  /// login failed, soft-logout, or the refresh attempt failed). The caller
  /// is responsible for obtaining a fresh JWT and calling [loginWithJwt].
  Future<matrix.Client?> getAuthenticatedClient(String did) async {
    final cached = _clientCache.get(did: did);
    if (cached == null) {
      return null;
    }

    final matrix.Client client;
    try {
      client = await cached;
    } catch (_) {
      return null;
    }

    if (client.accessToken == null) {
      return null;
    }

    if (_isTokenFresh(client)) {
      return client;
    }

    try {
      await client.refreshAccessToken();
      return client;
    } catch (_) {
      _clientCache.remove(did: did);
      return null;
    }
  }

  Future<matrix.Client> _login({
    required String did,
    required String jwt,
    matrix.Client? existing,
  }) async {
    final client = existing ?? await _createClient(did: did);
    await client.login(
      jwtLoginType,
      token: jwt,
      deviceId: deriveMatrixDeviceId(
        _config.deviceId,
        did,
        _config.homeserver.host,
      ),
    );
    return client;
  }

  /// Whether the client's access token is present and outside the
  /// [tokenGracePeriod] window.
  bool _isTokenFresh(matrix.Client client) {
    if (client.accessToken == null) {
      return false;
    }
    final expiresAt = client.accessTokenExpiresAt;
    if (expiresAt == null) {
      return true;
    }
    return DateTime.now().isBefore(expiresAt.subtract(tokenGracePeriod));
  }

  /// Creates a new [matrix.Client] instance for the given [did], without
  /// logging in. The caller is responsible for calling [loginWithJwt] to
  /// authenticate the client and cache the session.
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
  String deriveUserId(String did, String serverName) {
    return deriveMatrixUserId(did, serverName);
  }

  /// Disposes every cached matrix client and clears the session cache.
  /// Safe to call multiple times.
  Future<void> dispose() => _clientCache.dispose();
}
