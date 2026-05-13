import 'package:meeting_place_core/meeting_place_core.dart';

import '../protocol.dart';

/// A [DidCommOutgoingMessage] carrying a [ChatAliasProfileHash] protocol
/// payload — used to propose a profile-card update by sending the new hash.
class ChatAliasProfileHashMessage extends DidCommOutgoingMessage {
  ChatAliasProfileHashMessage({
    required super.senderDid,
    required super.recipientDid,
    required super.mediatorDid,
    required String profileHash,
  }) : super(
         payload: ChatAliasProfileHash.create(
           from: senderDid,
           to: [recipientDid],
           profileHash: profileHash,
         ).toPlainTextMessage(),
       );
}
