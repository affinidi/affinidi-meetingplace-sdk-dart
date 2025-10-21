import '../../exception/sdk_exception.dart';

enum GroupMembershipFinalizedExceptionCodes {
  connectionOfferGroupNotFound(
    'group_membership_finalized_connection_offer_group_not_found',
  ),
  connectionOfferAlreadyFinalizedException(
    'group_membership_finalized_connection_offer_already_finalized',
  ),
  groupConnectionOfferRequired(
    'group_membership_finalized_group_connection_offer_required',
  ),
  channelNotFound('group_membership_finalized_channel_not_found');

  const GroupMembershipFinalizedExceptionCodes(this.code);

  final String code;
}

class GroupMembershipFinalizedException implements SDKException {
  GroupMembershipFinalizedException({
    required this.message,
    required this.code,
    this.innerException,
  });

  factory GroupMembershipFinalizedException.connectionOfferAlreadyFinalizedException({
    required String offerLink,
    Object? innerException,
  }) {
    return GroupMembershipFinalizedException(
      message:
          '''GroupMembershipFinalized exception: ConnectionOfferAlreadyFinalizedException: Connection offer $offerLink already finalized''',
      code: GroupMembershipFinalizedExceptionCodes
          .connectionOfferGroupNotFound.name,
      innerException: innerException,
    );
  }

  factory GroupMembershipFinalizedException.channelNotFound({
    required String offerLink,
    Object? innerException,
  }) {
    return GroupMembershipFinalizedException(
      message:
          '''GroupMembershipFinalized exception: channel not found for offer link $offerLink''',
      code: GroupMembershipFinalizedExceptionCodes.channelNotFound.name,
      innerException: innerException,
    );
  }

  factory GroupMembershipFinalizedException.groupConnectionOfferRequired({
    required String offerLink,
    Object? innerException,
  }) {
    return GroupMembershipFinalizedException(
      message:
          '''GroupMembershipFinalized exception: connection offer for offer link $offerLink is not of type group''',
      code: GroupMembershipFinalizedExceptionCodes
          .groupConnectionOfferRequired.name,
      innerException: innerException,
    );
  }
  @override
  final String message;

  @override
  final String code;

  @override
  final Object? innerException;
}
