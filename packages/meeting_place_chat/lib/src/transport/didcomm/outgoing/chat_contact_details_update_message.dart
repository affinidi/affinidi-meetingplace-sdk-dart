import 'package:meeting_place_core/meeting_place_core.dart';

import '../protocol.dart';

/// A [DidCommOutgoingMessage] carrying a [ChatContactDetailsUpdate] protocol
/// payload — used to broadcast updated contact card details to the other
/// party over DIDComm.
class ChatContactDetailsUpdateMessage extends DidCommOutgoingMessage {
  ChatContactDetailsUpdateMessage({
    required super.senderDid,
    required super.recipientDid,
    required super.mediatorDid,
    required Map<String, dynamic> profileDetails,
  }) : super(
         payload: ChatContactDetailsUpdate.create(
           from: senderDid,
           to: [recipientDid],
           profileDetails: profileDetails,
         ).toPlainTextMessage(),
       );
}
