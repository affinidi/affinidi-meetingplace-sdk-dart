import 'package:meeting_place_core/meeting_place_core.dart';
import '../protocol.dart';

/// A [DidCommOutgoingMessage] carrying a [ChatActivity] protocol payload —
/// the "user is active" indicator sent over DIDComm.
class ChatActivityMessage extends DidCommOutgoingMessage {
  ChatActivityMessage({
    required super.senderDid,
    required super.recipientDid,
    required super.mediatorDid,
    required Duration forwardExpiry,
  }) : super(
         payload: ChatActivity.create(
           from: senderDid,
           to: [recipientDid],
         ).toPlainTextMessage(),
         ephemeral: true,
         forwardExpiryInSeconds: forwardExpiry.inSeconds,
       );
}
