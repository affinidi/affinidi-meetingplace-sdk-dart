import 'package:meeting_place_core/meeting_place_core.dart';

import '../protocol.dart';

/// A [DidCommOutgoingMessage] carrying a [ChatDelivered] protocol payload —
/// acknowledges receipt of one or more messages over DIDComm.
class ChatDeliveredMessage extends DidCommOutgoingMessage {
  ChatDeliveredMessage({
    required super.senderDid,
    required super.recipientDid,
    required super.mediatorDid,
    required List<String> messageIds,
  }) : super(
         payload: ChatDelivered.create(
           from: senderDid,
           to: [recipientDid],
           messages: messageIds,
         ).toPlainTextMessage(),
       );
}
