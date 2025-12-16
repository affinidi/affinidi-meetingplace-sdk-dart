import '../../exception/sdk_exception.dart';
import '../../meeting_place_core_sdk_error_code.dart';

class InvitationAcceptedGroupException implements SDKException {
  InvitationAcceptedGroupException({
    required this.message,
    required this.code,
    this.innerException,
  });

  factory InvitationAcceptedGroupException.contactCardNotPresent({
    Object? innerException,
  }) {
    return InvitationAcceptedGroupException(
      message:
          '''InvitationAcceptedGroup exception: Contact card not present in invitation accepted message''',
      code: MeetingPlaceCoreSDKErrorCode
          .invitationAcceptedGroupContactCardNotPresent,
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
