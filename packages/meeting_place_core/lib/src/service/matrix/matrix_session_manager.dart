import 'dart:async';

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

  /// Default [loginSyncGracePeriod] used by [loginWithJwt] when no
  /// override is supplied. Long enough for the Matrix SDK to complete its
  /// initial one-shot work (OTK upload, key queries, to-device processing).
  static const Duration loginSyncGracePeriod = Duration(seconds: 10);

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

  /// Tracks active room subscriptions per DID and per Matrix client.
  ///
  /// This lets us handle client replacement for the same DID: when a new
  /// client is introduced while existing subscriptions are still active,
  /// background sync is enabled for the new client as well.
  final Map<String, Map<matrix.Client, int>> _activeSubscriptions = {};

  /// Pending deactivation timers scheduled by [deactivateSync] when a
  /// [loginSyncGracePeriod] is set. Cancelled when [activateSync] is called
  /// again for the same client before the timer fires.
  final Map<matrix.Client, Timer> _pendingDeactivations = {};

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
  ///
  /// [loginSyncGracePeriod] controls how long background sync stays active
  /// after login before being automatically disabled. Defaults to
  /// [loginSyncGracePeriod]. Ignored when [keepSyncActiveAfterLogin]
  /// is `true`.
  ///
  /// [keepSyncActiveAfterLogin] when `true`, background sync is never
  /// automatically disabled — it stays active until [dispose] is called.
  ///
  /// **Note**: if a login for [did] is already in flight,
  /// [loginSyncGracePeriod] and [keepSyncActiveAfterLogin] from this call are
  /// ignored; the options from the first in-flight call take effect.
  Future<String> loginWithJwt({
    required String jwt,
    required String did,
    Duration loginSyncGracePeriod = loginSyncGracePeriod,
    bool keepSyncActiveAfterLogin = false,
  }) async {
    final loginFuture = _inFlightLogins.putIfAbsent(did, () async {
      final cached = _clientCache.get(did: did);
      matrix.Client? existingClient;
      if (cached != null) {
        try {
          existingClient = await cached;
          if (_isTokenFresh(existingClient)) {
            if (keepSyncActiveAfterLogin) {
              _pendingDeactivations.remove(existingClient)?.cancel();
            }
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

      final attempt = _login(
        did: did,
        jwt: jwt,
        existing: existingClient,
        loginSyncGracePeriod: loginSyncGracePeriod,
        keepSyncActiveAfterLogin: keepSyncActiveAfterLogin,
      );
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
    required Duration loginSyncGracePeriod,
    required bool keepSyncActiveAfterLogin,
  }) async {
    final client = existing ?? await _createClient(did: did);

    // Captures the per-call sync options so we don't repeat them on every
    // _schedulePostLoginDeactivation call below.
    void scheduleDeactivation() => _schedulePostLoginDeactivation(
      did,
      client,
      loginSyncGracePeriod: loginSyncGracePeriod,
      keepSyncActiveAfterLogin: keepSyncActiveAfterLogin,
    );

    // On a cold start the in-memory cache is empty and a fresh Client is
    // created with the persistent on-disk database.  Calling login() would
    // clear that database and generate a new OLM account, which causes
    // "Upload key failed" because the homeserver already has different OLM
    // identity keys registered for this device.  Instead, try to restore the
    // persisted session first so the existing OLM account is reused.
    if (client.accessToken == null) {
      await client.init(waitForFirstSync: false);
      // init() re-enables the sync loop when it restores a persisted session.
      // Schedule deactivation after the grace period so SDK housekeeping
      // (OTK upload, key queries) can complete first.
      scheduleDeactivation();
    }

    if (_isTokenFresh(client)) {
      _logger.info('Restored Matrix session for DID $did', name: _logKey);
      return client;
    }

    if (client.accessToken != null && await _tryRefreshToken(did, client)) {
      scheduleDeactivation();
      return client;
    }

    await client.login(
      jwtLoginType,
      token: jwt,
      deviceId: deriveMatrixDeviceId(
        _config.deviceId,
        did,
        _config.homeserver.host,
      ),
    );

    scheduleDeactivation();
    return client;
  }

  /// Attempts to silently refresh the access token for [client].
  ///
  /// Returns `true` on success. On failure, logs a warning and returns `false`
  /// so [_login] can fall through to a full JWT login.
  Future<bool> _tryRefreshToken(String did, matrix.Client client) async {
    try {
      await client.refreshAccessToken();
      _logger.info('Refreshed Matrix token for DID $did', name: _logKey);
      return true;
    } catch (_) {
      _logger.warning(
        '''Failed to refresh Matrix token for DID $did, falling back to full login''',
        name: _logKey,
      );
      return false;
    }
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

  /// Enables background sync for [client] when its first subscription for
  /// [did] is registered.
  ///
  /// Cancels any pending deactivation timer for [client] so that a new
  /// subscription arriving during the linger window seamlessly reactivates
  /// sync without an unnecessary stop/start cycle.
  ///
  /// Subscriptions are tracked per client instance so that, if a session is
  /// replaced mid-lifecycle, the replacement client is also switched to
  /// background sync.
  void activateSync(String did, matrix.Client client) {
    // Cancel any pending deactivation so re-subscribing during the linger
    // window is transparent.
    _pendingDeactivations.remove(client)?.cancel();

    final subscriptionsByClient = _activeSubscriptions.putIfAbsent(
      did,
      () => <matrix.Client, int>{},
    );
    final count = subscriptionsByClient[client] ?? 0;
    subscriptionsByClient[client] = count + 1;
    if (count == 0) {
      client.backgroundSync = true;
      _logger.info('Enabled background sync for DID $did', name: _logKey);
    }
  }

  /// Decrements the subscription counter for [did] and [client].
  ///
  /// When the counter reaches zero the client is considered idle and sync is
  /// stopped — either immediately (default) or after a delay:
  ///
  /// - [lingerDuration] `null`: sync is disabled synchronously.
  /// - [lingerDuration] a positive [Duration]: sync is disabled after that
  ///   delay unless [activateSync] is called again before the timer fires.
  /// - [keepSyncActive] `true`: sync is **never** automatically disabled for
  ///   this subscription; [lingerDuration] is ignored.
  void deactivateSync(
    String did,
    matrix.Client client, {
    Duration? lingerDuration,
    bool keepSyncActive = false,
  }) {
    final subscriptionsByClient = _activeSubscriptions[did];
    if (subscriptionsByClient == null) {
      return;
    }

    final count = (subscriptionsByClient[client] ?? 0) - 1;
    if (count <= 0) {
      subscriptionsByClient.remove(client);

      if (!keepSyncActive) {
        if (lingerDuration == null || lingerDuration == Duration.zero) {
          _disableSyncNow(did, client);
        } else {
          _scheduleDeactivation(did, client, lingerDuration);
        }
      }
    } else {
      subscriptionsByClient[client] = count;
    }

    if (subscriptionsByClient.isEmpty) {
      _activeSubscriptions.remove(did);
    }
  }

  /// Returns `true` if [client] has at least one active subscription across
  /// any DID. Used to check whether sync was re-enabled during a linger window.
  bool isBackgroundSyncActive(matrix.Client client) {
    return _activeSubscriptions.values.any(
      (byClient) => byClient.containsKey(client),
    );
  }

  void _disableSyncNow(String did, matrix.Client client) {
    _pendingDeactivations.remove(client)?.cancel();
    client.backgroundSync = false;
    _logger.info('Disabled background sync for DID $did', name: _logKey);
  }

  /// Schedules post-login sync deactivation using per-call options.
  ///
  /// When [keepSyncActiveAfterLogin] is `true`, this is a no-op — sync stays
  /// active until [dispose] is called.
  void _schedulePostLoginDeactivation(
    String did,
    matrix.Client client, {
    required Duration loginSyncGracePeriod,
    required bool keepSyncActiveAfterLogin,
  }) {
    if (keepSyncActiveAfterLogin) {
      _pendingDeactivations.remove(client)?.cancel();
      return;
    }

    _scheduleDeactivation(did, client, loginSyncGracePeriod);
  }

  void _scheduleDeactivation(String did, matrix.Client client, Duration delay) {
    _pendingDeactivations.remove(client)?.cancel();
    _logger.info(
      '''Scheduling background sync deactivation for DID $did in ${delay.inSeconds}s''',
      name: _logKey,
    );
    _pendingDeactivations[client] = Timer(delay, () {
      _pendingDeactivations.remove(client);
      if (!isBackgroundSyncActive(client)) {
        client.backgroundSync = false;
        _logger.info(
          'Disabled background sync for DID $did after linger',
          name: _logKey,
        );
      }
    });
  }

  /// Disposes every cached matrix client and clears the session cache.
  /// Safe to call multiple times.
  Future<void> dispose() async {
    _activeSubscriptions.clear();
    for (final timer in _pendingDeactivations.values) {
      timer.cancel();
    }
    _pendingDeactivations.clear();
    await _disposeClients(_clientCache.removeAll());
  }

  /// Disposes a single [client], swallowing errors so a failure does not
  /// propagate to the caller. The database is intentionally left open to
  /// avoid SQLITE_MISUSE from in-flight sync writes after abortSync returns.
  Future<void> _disposeClient(matrix.Client client) async {
    try {
      await client.dispose(closeDatabase: false);
    } catch (e, stackTrace) {
      _logger.error(
        'Error disposing Matrix client: $e',
        name: _logKey,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Disposes all clients in [futures], swallowing individual errors.
  Future<void> _disposeClients(List<Future<matrix.Client>> futures) async {
    for (final future in futures) {
      try {
        await _disposeClient(await future);
      } catch (e, stackTrace) {
        _logger.error(
          'Error disposing Matrix client: $e',
          name: _logKey,
          error: e,
          stackTrace: stackTrace,
        );
      }
    }
  }
}
