import 'dart:convert';
import 'package:didcomm/didcomm.dart';

import 'package:crypto/crypto.dart';
import 'package:ssi/ssi.dart';

import '../message/message_unpacker.dart';
import 'unpack_message_exception.dart';

/// A [FetchMessageResult] object returned after fetching messages from the mediator.
///
/// **Parameters:**
/// - [messageHash]: List of cryptographic hashes representing stored messages,
/// used to verify and track messages without exposing their content.
/// - [message]: The [PlainTextMessage] that was delivered.
/// - [error]: An error occurred while fetching the message.
class FetchMessageResult {
  FetchMessageResult({required this.messageHash, this.message, this.error});
  final String messageHash;
  final PlainTextMessage? message;
  final String? error;

  /// A constructor that initializes a [FetchMessageResult] from a message.
  ///
  /// **Parameters:**
  /// - [didManager]: The DidManager instance used for authentication with the
  ///   mediator. This contains the identity credentials needed for the session.
  static Future<FetchMessageResult> fromMessage(
    Map<String, dynamic> message, {
    required DidManager didManager,
    List<MessageWrappingType>? expectedMessageWrappingTypes,
  }) async {
    final messageHash = sha256.convert(utf8.encode(jsonEncode(message)));
    try {
      return FetchMessageResult(
        message: await MessageUnpacker.unpackWithRetry(
          message: message,
          recipientDidManager: didManager,
          expectedMessageWrappingTypes: expectedMessageWrappingTypes,
        ),
        messageHash: messageHash.toString(),
      );
    } catch (e) {
      throw UnpackMessageException(innerException: e, messageHash: messageHash);
    }
  }
}
