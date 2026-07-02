import '../../../matrix_outgoing_message.dart';

import '../matrix_chat_event_type.dart';

class ProfileHashRoomEvent extends MatrixOutgoingMessage {
  ProfileHashRoomEvent({required super.senderDid, required String profileHash})
    : super(
        type: MatrixChatEventType.profileHash,
        content: {'profile_hash': profileHash},
      );
}
