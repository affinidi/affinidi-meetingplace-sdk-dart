import 'package:meeting_place_core/meeting_place_core.dart';

import '../protocol.dart';

/// A [DidCommOutgoingMessage] carrying a [ChatPresence] protocol payload.
class ChatPresenceMessage extends DidCommOutgoingMessage {
  ChatPresenceMessage({
    required super.senderDid,
    required super.recipientDid,
    required super.mediatorDid,
    required Duration forwardExpiry,
  }) : super(
         payload: ChatPresence.create(
           from: senderDid,
           to: [recipientDid],
         ).toPlainTextMessage(),
         forwardExpiryInSeconds: forwardExpiry.inSeconds,
       );
}
