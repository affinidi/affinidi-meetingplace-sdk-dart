import 'package:meeting_place_core/meeting_place_core.dart';

class ProfileHashRoomEvent extends MatrixOutgoingMessage {
  ProfileHashRoomEvent({
    required super.senderDid,
    required super.roomId,
    required String profileHash,
  }) : super(
         type: 'com.affinidi.chat.profile-hash',
         content: {'profile_hash': profileHash},
       );
}
