import '../../core/exception/control_plane_exception.dart';
import '../../control_plane_sdk_error_code.dart';

/// A concrete implementation of the [ControlPlaneException] interface for
/// throwing specific exceptions related to the Notify Channel Group
/// command/operation.
class NotifyChannelGroupException implements ControlPlaneException {
  NotifyChannelGroupException._({
    required this.message,
    required this.code,
    this.innerException,
  });

  /// Creates a `generic` [NotifyChannelGroupException] instance.
  factory NotifyChannelGroupException.generic({Object? innerException}) {
    return NotifyChannelGroupException._(
      message: 'Notify channel group exception: ${innerException.toString()}.',
      code: ControlPlaneSDKErrorCode.notifyChannelGroupGeneric,
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
