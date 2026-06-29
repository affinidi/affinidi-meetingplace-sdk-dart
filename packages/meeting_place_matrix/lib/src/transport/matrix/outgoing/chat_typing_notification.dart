import '../../../matrix_outgoing_message.dart';

/// A [MatrixOutgoingMessage] that controls the Matrix typing indicator.
///
/// When `active` is `true`, the underlying Matrix transport sends an
/// `m.typing` notification for the given `timeoutMs`. When `false`, the
/// typing indicator is cleared regardless of timeout.
class ChatTypingNotification extends MatrixOutgoingMessage {
  ChatTypingNotification({
    required super.senderDid,
    required bool active,
    int? timeoutMs,
  }) : super(
         type: 'm.typing',
         content: {'active': active, 'timeoutMs': timeoutMs},
       );
}
