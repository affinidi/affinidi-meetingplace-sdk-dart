import 'package:matrix/matrix.dart' show EventTypes;
import 'package:meeting_place_chat/meeting_place_chat.dart';
import '../../../matrix_outgoing_message.dart';

import '../matrix_mentions.dart';

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
    List<ChatMention> mentions = const [],
    super.notification,
  }) : super(
         type: EventTypes.Message,
         content: {
           ...buildMatrixTextContent(
             text: '* $newText',
             mentions: _offsetMentions(mentions, 2),
           ),
           'm.new_content': buildMatrixTextContent(
             text: newText,
             mentions: mentions,
           ),
           'm.relates_to': {'rel_type': 'm.replace', 'event_id': targetEventId},
         },
       );
}

List<ChatMention> _offsetMentions(List<ChatMention> mentions, int delta) {
  return [
    for (final mention in mentions)
      ChatMention(
        target: mention.target,
        start: mention.start + delta,
        length: mention.length,
        display: mention.display,
        isRoomMention: mention.isRoomMention,
      ),
  ];
}
