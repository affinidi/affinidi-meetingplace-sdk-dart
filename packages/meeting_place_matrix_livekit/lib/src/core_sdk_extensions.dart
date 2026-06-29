import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_matrix/meeting_place_matrix.dart'
    show deriveRoomAliasLocalpart;

extension MeetingPlaceMatrixLiveKitSDKExtension on MeetingPlaceCoreSDK {
  /// Returns the deterministic LiveKit room name for a channel.
  String livekitRoomName({
    required String channelDid,
    String? otherPartyChannelDid,
  }) => deriveRoomAliasLocalpart(
    channelDid: channelDid,
    otherPartyChannelDid: otherPartyChannelDid,
  );
}
