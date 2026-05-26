import 'package:meeting_place_core/meeting_place_core.dart';

import '../../../protocol/protocol.dart';

/// A [DidCommOutgoingMessage] carrying a [ChatActivity] protocol payload —
/// the "user is active" indicator sent over DIDComm.
class ChatActivityMessage extends DidCommOutgoingMessage {
  ChatActivityMessage({
    required super.senderDid,
    required String recipientDid,
    required super.mediatorDid,
    required Duration forwardExpiry,
  }) : super(
         recipientDid: recipientDid,
         payload: ChatActivity.create(
           from: senderDid,
           to: [recipientDid],
         ).toPlainTextMessage(),
         ephemeral: true,
         forwardExpiryInSeconds: forwardExpiry.inSeconds,
       );
}
