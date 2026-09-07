import '../../core/exception/control_plane_exception.dart';
import '../../meeting_place_control_plane_sdk_error_code.dart';

class NotifyOutreachException implements ControlPlaneException {
  NotifyOutreachException({
    required this.message,
    required this.code,
    this.innerException,
  });

  factory NotifyOutreachException.generic({Object? innerException}) {
    return NotifyOutreachException(
      message: 'Notify outreach exception: ${innerException.toString()}.',
      code: MeetingPlaceControlPlaneSDKErrorCode.notifyOutreachGeneric,
      innerException: innerException,
    );
  }
  @override
  final String message;

  @override
  final MeetingPlaceControlPlaneSDKErrorCode code;

  @override
  final Object? innerException;
}
