import 'package:meeting_place_core/meeting_place_core.dart';

class ProfileRequestRoomEvent extends MatrixOutgoingMessage {
  ProfileRequestRoomEvent({
    required super.senderDid,
    required super.roomId,
    required String profileHash,
  }) : super(
         type: 'com.affinidi.chat.profile-request',
         content: {'profile_hash': profileHash},
       );
}
