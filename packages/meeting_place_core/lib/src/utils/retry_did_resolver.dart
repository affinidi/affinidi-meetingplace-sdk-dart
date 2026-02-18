import 'dart:async';

import 'package:retry/retry.dart';
import 'package:ssi/ssi.dart';

import '../../meeting_place_core.dart';
import 'error_handler_utils.dart';

class RetryDidResolver implements DidResolver {
  RetryDidResolver({
    this.resolverAddress,
    required MeetingPlaceCoreSDKLogger logger,
  }) : _logger = logger;

  static final int _maxRetryAttempts = 3;
  static final Duration _maxRetryDelay = const Duration(seconds: 2);

  final String? resolverAddress;
  final MeetingPlaceCoreSDKLogger _logger;

  @override
  Future<DidDocument> resolveDid(String did) async {
    final didDocument = await retry(
      () async {
        return await UniversalDIDResolver(
          resolverAddress: resolverAddress,
        ).resolveDid(did);
      },
      retryIf: (e) => ErrorHandlerUtils.isRetryableError(e),
      onRetry: (e) => _logger.warning(
        'Retrying unpacking message due to error: $e',
        name: 'resolveDid',
      ),
      maxAttempts: _maxRetryAttempts,
      maxDelay: _maxRetryDelay,
    );

    return didDocument;
  }
}
