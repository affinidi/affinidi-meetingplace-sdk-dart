import '../../../matrix_outgoing_message.dart';

/// A [MatrixOutgoingMessage] used to send a raw Matrix event with an
/// arbitrary [type] and [content] payload. Used by chat features that don't
/// have a dedicated message class.
class MatrixCustomOutgoingMessage extends MatrixOutgoingMessage {
  MatrixCustomOutgoingMessage({
    required super.senderDid,
    required super.type,
    required super.content,
  });
}
