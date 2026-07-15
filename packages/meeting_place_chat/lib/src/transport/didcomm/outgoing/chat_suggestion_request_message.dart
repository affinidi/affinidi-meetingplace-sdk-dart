import 'package:meeting_place_core/meeting_place_core.dart';

import '../protocol.dart';

/// A [DidCommOutgoingMessage] carrying a [ChatSuggestionRequest] payload.
class ChatSuggestionRequestMessage extends DidCommOutgoingMessage {
  ChatSuggestionRequestMessage({
    required super.senderDid,
    required super.recipientDid,
    required super.mediatorDid,
    required String messageId,
    required String text,
  }) : super(
         payload: ChatSuggestionRequest.create(
           from: senderDid,
           to: [recipientDid],
           messageId: messageId,
           text: text,
         ).toPlainTextMessage(),
       );
}
