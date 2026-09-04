import '../call_media_type.dart';

/// Parameters for `MeetingPlaceMatrixSDK.ringGroupMember`.
class RingGroupMemberRequest {
  const RingGroupMemberRequest({
    required this.groupChannelDid,
    required this.memberDid,
    required this.mediaType,
  });

  /// The group's permanent channel DID.
  final String groupChannelDid;

  /// The DID of the group member to ring.
  final String memberDid;

  /// The media type (audio/video) to ring with.
  final CallMediaType mediaType;
}
