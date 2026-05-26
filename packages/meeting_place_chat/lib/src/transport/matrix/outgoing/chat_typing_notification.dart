import 'package:meeting_place_core/meeting_place_core.dart';

/// A [MatrixOutgoingMessage] that controls the Matrix typing indicator.
///
/// When [active] is `true`, the underlying Matrix transport sends an
/// `m.typing` notification for the given [timeoutMs]. When `false`, the
/// typing indicator is cleared regardless of timeout.
class ChatTypingNotification extends MatrixOutgoingMessage {
  ChatTypingNotification({
    required super.senderDid,
    required super.roomId,
    required bool active,
    int? timeoutMs,
  }) : super(
         type: 'm.typing',
         content: {'active': active, 'timeoutMs': timeoutMs},
       );
}
