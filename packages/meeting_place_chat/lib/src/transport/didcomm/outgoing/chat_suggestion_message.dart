import 'package:meeting_place_core/meeting_place_core.dart';

import '../protocol.dart';

/// A [DidCommOutgoingMessage] carrying a [ChatSuggestion] payload.
class ChatSuggestionMessage extends DidCommOutgoingMessage {
  ChatSuggestionMessage({
    required super.senderDid,
    required super.recipientDid,
    required super.mediatorDid,
    required String relatedMessageId,
    required String text,
  }) : super(
         payload: ChatSuggestion.create(
           from: senderDid,
           to: [recipientDid],
           relatedMessageId: relatedMessageId,
           text: text,
         ).toPlainTextMessage(),
       );
}