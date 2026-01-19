import 'dart:async';
import 'dart:io';

import 'package:retry/retry.dart';
import 'package:ssi/ssi.dart';

import '../../meeting_place_core.dart';

class CachedDidResolver implements DidResolver {
  CachedDidResolver({
    this.resolverAddress,
    required MeetingPlaceCoreSDKLogger logger,
  }) : _logger = logger;

  static final Map<String, DidDocument> cacheDIDDocs = {};
  static final int _maxRetryAttempts = 3;
  static final Duration _maxRetryDelay = const Duration(seconds: 2);

  final String? resolverAddress;
  final MeetingPlaceCoreSDKLogger _logger;

  @override
  Future<DidDocument> resolveDid(String did) async {
    if (cacheDIDDocs.containsKey(did)) {
      return cacheDIDDocs[did]!;
    }

    final didDocument = await retry(
      () async => await UniversalDIDResolver(
        resolverAddress: resolverAddress,
      ).resolveDid(did),
      retryIf: (e) =>
          e is SsiException && e.code == 'invalid_did_web' ||
          e is SocketException ||
          e is TimeoutException ||
          e is HttpException ||
          e is HandshakeException ||
          e is TlsException,
      onRetry: (e) => _logger.warning(
        'Retrying unpacking message due to error: $e',
        name: 'resolveDid',
      ),
      maxAttempts: _maxRetryAttempts,
      maxDelay: _maxRetryDelay,
    );

    cacheDIDDocs[didDocument.id] = didDocument;
    return didDocument;
  }
}
