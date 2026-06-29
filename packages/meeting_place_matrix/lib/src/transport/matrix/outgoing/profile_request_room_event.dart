import '../../../matrix_outgoing_message.dart';

import '../matrix_chat_event_type.dart';

class ProfileRequestRoomEvent extends MatrixOutgoingMessage {
  ProfileRequestRoomEvent({
    required super.senderDid,
    required String profileHash,
  }) : super(
         type: MatrixChatEventType.profileRequest,
         content: {'profile_hash': profileHash},
       );
}
