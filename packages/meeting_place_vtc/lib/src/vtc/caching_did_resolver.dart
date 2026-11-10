import 'dart:async';

import 'package:ssi/ssi.dart';

/// Keeps what [_inner] resolves for [ttl], so that the many requests of one
/// screen do not each fetch and verify a community's `did:webvh` log again.
///
/// Requests for a DID already being resolved share that resolution. A
/// failure is not kept: the next request resolves again. A document changed
/// by its controller, e.g. a rotated key, is seen once [ttl] has passed.
class CachingDidResolver implements DidResolver {
  /// Creates a [CachingDidResolver] in front of [_inner].
  CachingDidResolver(
    this._inner, {
    this.ttl = const Duration(minutes: 5),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// How long a resolved document is kept.
  final Duration ttl;

  final DidResolver _inner;
  final DateTime Function() _now;
  final Map<String, ({Future<DidDocument> document, DateTime resolvedAt})>
  _resolved = {};

  @override
  Future<DidDocument> resolveDid(String did) {
    final kept = _resolved[did];
    if (kept != null && _now().difference(kept.resolvedAt) < ttl) {
      return kept.document;
    }
    final document = _inner.resolveDid(did);
    _resolved[did] = (document: document, resolvedAt: _now());
    unawaited(
      document.then(
        (_) {},
        onError: (Object _) {
          // Only this failed attempt is forgotten, not a later one's result.
          if (identical(_resolved[did]?.document, document)) {
            _resolved.remove(did);
          }
        },
      ),
    );
    return document;
  }
}
