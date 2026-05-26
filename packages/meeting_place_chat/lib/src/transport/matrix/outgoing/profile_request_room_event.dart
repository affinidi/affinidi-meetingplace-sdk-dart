import 'package:meeting_place_core/meeting_place_core.dart';

import '../chat_protocol.dart';

class ProfileRequestRoomEvent extends MatrixOutgoingMessage {
  ProfileRequestRoomEvent({
    required super.senderDid,
    required super.roomId,
    required String profileHash,
  }) : super(
         type: ChatProtocol.chatAliasProfileRequest.value,
         content: {'profile_hash': profileHash},
       );
}
