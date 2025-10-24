import 'package:didcomm/didcomm.dart';

/// Represents an object returned after fetching messages from the mediator.
///
/// **Parameters**
/// - [message]: The [PlainTextMessage] that was delivered.
/// - [messageHash]: Cryptographic hash which represents stored message,
/// used to verify and track message without exposing the content.
class FetchMessageResult {
  FetchMessageResult({required this.message, required this.messageHash});
  final PlainTextMessage message;
  final String messageHash;
}
