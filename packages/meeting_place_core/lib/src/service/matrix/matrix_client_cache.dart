import 'package:matrix/matrix.dart' as matrix;

/// Cache for in-flight and resolved Matrix client logins, keyed by user DID
/// and homeserver. Storing `Future<matrix.Client>` (rather than the resolved
/// client) lets concurrent callers share a single login attempt and prevents
/// readers from observing an unauthenticated client.
class MatrixClientCache {
  MatrixClientCache({required this.homeserver});

  /// The Matrix homeserver URI, used as part of the cache key.
  final Uri homeserver;

  /// Internal cache mapping a composite key of DID and homeserver to the
  /// in-flight (or resolved) login Future for that user and homeserver.
  final Map<String, Future<matrix.Client>> _clientCache = {};

  /// Stores [future] in the cache for the given [did], replacing any existing
  /// entry. The caller is expected to have checked for a usable existing
  /// session before invoking this — the `get`-then-`add` sequence runs without
  /// yielding in Dart's single-threaded event loop, so concurrent callers
  /// cannot race past `get`.
  void add({required String did, required Future<matrix.Client> future}) {
    final cacheKey = _getCacheKey(did: did);
    _clientCache[cacheKey] = future;
  }

  /// Retrieves the cached login Future for the given [did], or null if no
  /// login has been started for that user and homeserver.
  Future<matrix.Client>? get({required String did}) {
    final cacheKey = _getCacheKey(did: did);
    return _clientCache[cacheKey];
  }

  /// Removes the cached entry for the given [did], if it exists. Used to
  /// clear the session when authentication fails or the token cannot be
  /// refreshed.
  void remove({required String did}) {
    final cacheKey = _getCacheKey(did: did);
    _clientCache.remove(cacheKey);
  }

  /// Disposes every cached client (aborting their sync loops) and clears
  /// the cache. The underlying database is intentionally left open so
  /// in-flight sync responses that arrive after `abortSync` returns do
  /// not crash with `SQLITE_MISUSE` while writing to a closed handle;
  /// the database file is reaped with the temp directory by the OS or
  /// by an explicit cleanup. Errors from individual clients are
  /// swallowed so a single failure cannot block the rest.
  Future<void> dispose() async {
    final futures = _clientCache.values.toList();
    _clientCache.clear();
    for (final future in futures) {
      try {
        final client = await future;
        await client.dispose(closeDatabase: false);
      } catch (_) {
        // Ignore — best-effort cleanup.
      }
    }
  }

  String _getCacheKey({required String did}) {
    return '$did._${homeserver.toString()}';
  }
}
