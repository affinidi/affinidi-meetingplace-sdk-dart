import '../../exception/sdk_exception.dart';
import '../../meeting_place_core_sdk_error_code.dart';

class MediatorAclException implements SDKException {
  MediatorAclException({
    required this.message,
    required this.code,
    this.innerException,
  });

  factory MediatorAclException.missingPermanentChannelDids() {
    return MediatorAclException(
      message:
          '''Mediator ACL exception: Cannot remove permission from channel without permanent DIDs.''',
      code: MeetingPlaceCoreSDKErrorCode.mediatorAclMissingChannelDids,
    );
  }
  @override
  final String message;

  @override
  final MeetingPlaceCoreSDKErrorCode code;

  @override
  final Object? innerException;
}
