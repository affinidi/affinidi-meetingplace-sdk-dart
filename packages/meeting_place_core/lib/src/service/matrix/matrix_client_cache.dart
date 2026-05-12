import 'package:matrix/matrix.dart' as matrix;
import 'matrix_client.dart';

/// Cache for Matrix client instances, keyed by user DID and homeserver.
class MatrixClientCache {
  MatrixClientCache({required this.homeserver});

  /// The Matrix homeserver URI, used as part of the cache key.
  final Uri homeserver;

  /// Internal cache mapping a composite key of DID and homeserver to the
  /// authenticated Matrix client instance for that user and homeserver.
  final Map<String, matrix.Client> _clientCache = {};

  /// Adds a new authenticated client to the cache for the given [did]. The
  /// cache key is derived from the [did] and the [homeserver] URI.
  ///
  /// If a client already exists in the cache for the same key, it will be
  /// returned without adding the new client.
  ///
  /// Parameters:
  /// - [did]: The DID of the user for whom the client is being added, used
  ///   to derive the cache key.
  /// - [client]: The authenticated Matrix client instance to be cached for
  ///   the user.
  ///
  /// Returns: The cached client instance for the user, which may be the newly
  /// added client or an existing one if a client was already cached for the
  /// same key.
  matrix.Client add({required String did, required matrix.Client client}) {
    final cacheKey = _getCacheKey(did: did);
    return _clientCache.putIfAbsent(cacheKey, () => client);
  }

  /// Retrieves the cached client for the given [did], or null if no client is
  /// cached for that user and homeserver.
  ///
  /// Parameters:
  /// - [did]: The DID of the user for whom to retrieve the cached client,
  ///   used to derive the cache key.
  ///
  /// Returns: The cached Matrix client instance for the user, or null if no
  /// client is cached for the given key.
  matrix.Client? get({required String did}) {
    final cacheKey = _getCacheKey(did: did);
    return _clientCache[cacheKey];
  }

  /// Removes the cached client for the given [did], if it exists. This is used
  /// to clear the session for a user when authentication fails or the session
  /// expires.
  ///
  /// Parameters:
  /// - [did]: The DID of the user for whom to remove the cached client,
  ///   used to derive the cache key.
  void remove({required String did}) {
    final cacheKey = _getCacheKey(did: did);
    _clientCache.remove(cacheKey);
  }

  /// Clears all cached clients from the cache.
  void dispose() {
    _clientCache.clear();
  }

  /// Derives a cache key from the given [did] and the [homeserver] URI. The key
  /// is a combination of the DID and the homeserver to ensure uniqueness across
  /// different users and homeservers.
  ///
  /// Parameters:
  /// - [did]: The DID of the user, used as part of the cache key
  ///
  /// Returns: A string representing the cache key for the given DID and homeserver.
  String _getCacheKey({required String did}) {
    return '$did._${homeserver.toString()}';
  }
}
