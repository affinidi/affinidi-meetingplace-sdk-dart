import 'package:matrix/matrix.dart' show EventTypes;
import 'package:meeting_place_chat/meeting_place_chat.dart';
import '../../../matrix_outgoing_message.dart';

import '../matrix_mentions.dart';

/// A [MatrixOutgoingMessage] specialised for plain-text chat messages.
///
/// Fixes the Matrix event type to [EventTypes.Message] and builds the
/// standard `m.text` content map from the supplied `text`.
class TextMessageRoomEvent extends MatrixOutgoingMessage {
  TextMessageRoomEvent({
    required super.senderDid,
    required String text,
    List<ChatMention> mentions = const [],
    super.notification,
  }) : super(
         type: EventTypes.Message,
         content: buildMatrixTextContent(text: text, mentions: mentions),
       );
}
