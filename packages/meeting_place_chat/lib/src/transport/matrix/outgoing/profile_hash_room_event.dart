import 'package:meeting_place_core/meeting_place_core.dart';

import '../chat_protocol.dart';

class ProfileHashRoomEvent extends MatrixOutgoingMessage {
  ProfileHashRoomEvent({
    required super.senderDid,
    required super.roomId,
    required String profileHash,
  }) : super(
         type: ChatProtocol.chatAliasProfileHash.value,
         content: {'profile_hash': profileHash},
       );
}
