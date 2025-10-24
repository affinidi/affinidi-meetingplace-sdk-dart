import '../../exception/sdk_exception.dart';
import '../../meeting_place_core_sdk_error_code.dart';

class GroupException implements SDKException {
  GroupException({
    required this.message,
    required this.code,
    this.innerException,
  });

  factory GroupException.notFoundError({Object? innerException}) {
    return GroupException(
      message: 'Group exception: group not found.',
      code: MeetingPlaceCoreSDKErrorCode.groupNotFoundError,
      innerException: innerException,
    );
  }

  factory GroupException.memberDoesNotBelongToGroupError({
    Object? innerException,
  }) {
    return GroupException(
      message: 'Group exception: member does not belong to group.',
      code: MeetingPlaceCoreSDKErrorCode.groupMemberDoesNotBelongToGroupError,
      innerException: innerException,
    );
  }

  factory GroupException.offerDoesNotExistError({Object? innerException}) {
    return GroupException(
      message: 'Group exception: offer does not exist.',
      code: MeetingPlaceCoreSDKErrorCode.groupOfferDoesNotExistError,
      innerException: innerException,
    );
  }

  factory GroupException.memberDidIsNull({Object? innerException}) {
    return GroupException(
      message: 'Group exception: member did is null.',
      code: MeetingPlaceCoreSDKErrorCode.groupMemberDidIsNull,
      innerException: innerException,
    );
  }

  factory GroupException.channelDoesNotExistError({Object? innerException}) {
    return GroupException(
      message: 'Group exception: channel does not exist.',
      code: MeetingPlaceCoreSDKErrorCode.groupChannelDoesNotExistError,
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
