import '../../exception/sdk_exception.dart';

enum GroupExceptionCodes {
  notFoundError('group_not_found_error'),
  memberDidIsNull('member_did_is_null'),
  memberDoesNotBelongToGroupError(
    'group_member_does_not_belong_to_group_error',
  ),
  offerDoesNotExistError('group_offer_does_not_exist_error'),
  channelDoesNotExistError('group_offer_channel_does_not_exist_error');

  const GroupExceptionCodes(this.code);

  final String code;
}

class GroupException implements SDKException {
  GroupException({
    required this.message,
    required this.code,
    this.innerException,
  });

  factory GroupException.notFoundError({Object? innerException}) {
    return GroupException(
      message: 'Group exception: group not found.',
      code: GroupExceptionCodes.notFoundError.name,
      innerException: innerException,
    );
  }

  factory GroupException.memberDoesNotBelongToGroupError({
    Object? innerException,
  }) {
    return GroupException(
      message: 'Group exception: member does not belong to group.',
      code: GroupExceptionCodes.memberDoesNotBelongToGroupError.name,
      innerException: innerException,
    );
  }

  factory GroupException.offerDoesNotExistError({Object? innerException}) {
    return GroupException(
      message: 'Group exception: offer does not exist.',
      code: GroupExceptionCodes.offerDoesNotExistError.name,
      innerException: innerException,
    );
  }

  factory GroupException.memberDidIsNull({Object? innerException}) {
    return GroupException(
      message: 'Group exception: member did is null.',
      code: GroupExceptionCodes.memberDidIsNull.name,
      innerException: innerException,
    );
  }

  factory GroupException.channelDoesNotExistError({Object? innerException}) {
    return GroupException(
      message: 'Group exception: channel does not exist.',
      code: GroupExceptionCodes.channelDoesNotExistError.name,
      innerException: innerException,
    );
  }
  @override
  final String message;

  final String code;

  @override
  final Object? innerException;
}
