import 'package:meeting_place_core/meeting_place_core.dart';

import '../protocol.dart';

/// A [DidCommOutgoingMessage] carrying a [ChatAliasProfileRequest] protocol
/// payload — used to request the full contact card behind a previously
/// announced profile hash.
class ChatAliasProfileRequestMessage extends DidCommOutgoingMessage {
  ChatAliasProfileRequestMessage({
    required super.senderDid,
    required super.recipientDid,
    required super.mediatorDid,
    required String profileHash,
  }) : super(
         payload: ChatAliasProfileRequest.create(
           from: senderDid,
           to: [recipientDid],
           profileHash: profileHash,
         ).toPlainTextMessage(),
       );
}
