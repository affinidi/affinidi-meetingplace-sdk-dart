import '../../exception/sdk_exception.dart';
import '../../meeting_place_core_sdk_error_code.dart';

class GroupMembershipFinalisedException implements SDKException {
  GroupMembershipFinalisedException({
    required this.message,
    required this.code,
    this.innerException,
  });

  // ignore: lines_longer_than_80_chars
  factory GroupMembershipFinalisedException.connectionOfferAlreadyFinalizedException({
    required String offerLink,
    Object? innerException,
  }) {
    return GroupMembershipFinalisedException(
      message:
          '''GroupMembershipFinalised exception: Connection offer $offerLink already finalized''',
      code: MeetingPlaceCoreSDKErrorCode
          .groupMembershipFinalisedConnectionOfferGroupNotFound,
      innerException: innerException,
    );
  }

  factory GroupMembershipFinalisedException.channelNotFound({
    required String offerLink,
    Object? innerException,
  }) {
    return GroupMembershipFinalisedException(
      message:
          '''GroupMembershipFinalized exception: channel not found for offer link $offerLink''',
      code:
          MeetingPlaceCoreSDKErrorCode.groupMembershipFinalisedChannelNotFound,
      innerException: innerException,
    );
  }

  factory GroupMembershipFinalisedException.groupConnectionOfferRequired({
    required String offerLink,
    Object? innerException,
  }) {
    return GroupMembershipFinalisedException(
      message:
          '''GroupMembershipFinalized exception: connection offer for offer link $offerLink is not of type group''',
      code: MeetingPlaceCoreSDKErrorCode
          .groupMembershipFinalisedGroupConnectionOfferRequired,
      innerException: innerException,
    );
  }
  @override
  final String message;

  @override
  final MeetingPlaceCoreSDKErrorCode code;

  @override
  final Object? innerException;
}
