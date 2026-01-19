import 'dart:async';
import 'dart:io';

import 'package:didcomm/didcomm.dart';
import 'package:retry/retry.dart';
import 'package:ssi/ssi.dart';

/// A utility class for unpacking DIDComm messages with retry logic.
class MessageUnpacker {
  static final int _maxRetryAttempts = 3;
  static final Duration _maxRetryDelay = Duration(seconds: 2);

  /// Unpacks a DIDComm message to a PlainTextMessage with automatic retry on failure.
  ///
  /// **Parameters:**
  /// - [message]: The encrypted DIDComm message to unpack.
  /// - [recipientDidManager]: The DidManager instance for the message recipient.
  /// - [expectedMessageWrappingTypes]: Optional list of expected message wrapping types.
  ///
  /// Returns a [PlainTextMessage] after successful unpacking.
  static Future<PlainTextMessage> unpackWithRetry({
    required Map<String, dynamic> message,
    required DidManager recipientDidManager,
    List<MessageWrappingType>? expectedMessageWrappingTypes,
    Function(Exception e)? onRetry,
  }) async {
    return retry(
      () async {
        return await DidcommMessage.unpackToPlainTextMessage(
          message: message,
          recipientDidManager: recipientDidManager,
          expectedMessageWrappingTypes: expectedMessageWrappingTypes,
        );
      },
      retryIf: (e) =>
          e is SsiException && e.code == 'invalid_did_web' ||
          e is SocketException ||
          e is TimeoutException ||
          e is HttpException ||
          e is HandshakeException ||
          e is TlsException,
      onRetry: (e) => onRetry?.call(e),
      maxAttempts: _maxRetryAttempts,
      maxDelay: _maxRetryDelay,
    );
  }
}
