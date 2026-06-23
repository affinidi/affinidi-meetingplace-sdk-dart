import 'package:meeting_place_core/meeting_place_core.dart';

import '../matrix_chat_event_type.dart';

class ProfileHashRoomEvent extends MatrixOutgoingMessage {
  ProfileHashRoomEvent({required super.senderDid, required String profileHash})
    : super(
        type: MatrixChatEventType.profileHash,
        content: {'profile_hash': profileHash},
      );
}
