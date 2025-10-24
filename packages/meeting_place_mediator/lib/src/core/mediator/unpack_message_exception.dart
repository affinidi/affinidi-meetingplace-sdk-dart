import 'package:crypto/crypto.dart';

/// Represents an exception that occurs during unpacking of the message.
///
/// **Parameters**
/// - [innerException]: Provide a reference to the exception that caused the current exception to be thrown.
/// - [messageHash]: Cryptographic hash which represents stored message,
/// used to verify and track message without exposing the content.
class UnpackMessageException implements Exception {
  UnpackMessageException({
    required this.innerException,
    required this.messageHash,
  });
  final Object innerException;
  final Digest messageHash;
}
