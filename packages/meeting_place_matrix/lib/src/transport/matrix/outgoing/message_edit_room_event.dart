import 'package:matrix/matrix.dart' show EventTypes;
import '../../../matrix_outgoing_message.dart';

/// A [MatrixOutgoingMessage] that replaces the body of a previously sent
/// `m.room.message` using the Matrix `m.replace` relation.
///
/// The event type is `m.room.message` (same as a normal text message); the
/// edit semantics are carried in `m.relates_to.rel_type = 'm.replace'` and
/// `m.new_content`. The top-level `body` is a `"* <newText>"` fallback for
/// clients that do not understand the relation.
class MessageEditRoomEvent extends MatrixOutgoingMessage {
  MessageEditRoomEvent({
    required super.senderDid,
    required String targetEventId,
    required String newText,
    super.notification,
  }) : super(
         type: EventTypes.Message,
         content: {
           'msgtype': 'm.text',
           'body': '* $newText',
           'm.new_content': {'msgtype': 'm.text', 'body': newText},
           'm.relates_to': {'rel_type': 'm.replace', 'event_id': targetEventId},
         },
       );
}
