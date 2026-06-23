import 'package:meeting_place_core/meeting_place_core.dart';

import '../protocol.dart';

/// A [DidCommOutgoingMessage] carrying a [ChatReaction] protocol payload.
class ChatReactionMessage extends DidCommOutgoingMessage {
  ChatReactionMessage({
    required super.senderDid,
    required super.recipientDid,
    required super.mediatorDid,
    required List<String> reactions,
    required String messageId,
  }) : super(
         payload: ChatReaction.create(
           from: senderDid,
           to: [recipientDid],
           reactions: reactions,
           messageId: messageId,
         ).toPlainTextMessage(),
       );
}
