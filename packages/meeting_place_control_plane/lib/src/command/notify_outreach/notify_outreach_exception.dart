import '../../control_plane_sdk_error_code.dart';
import '../../core/exception/control_plane_exception.dart';

class NotifyOutreachException implements ControlPlaneException {
  NotifyOutreachException({
    required this.message,
    required this.code,
    this.innerException,
  });

  factory NotifyOutreachException.generic({Object? innerException}) {
    return NotifyOutreachException(
      message: 'Notify outreach exception: ${innerException.toString()}.',
      code: ControlPlaneSDKErrorCode.notifyOutreachGeneric,
      innerException: innerException,
    );
  }
  @override
  final String message;

  @override
  final ControlPlaneSDKErrorCode code;

  @override
  final Object? innerException;
}
