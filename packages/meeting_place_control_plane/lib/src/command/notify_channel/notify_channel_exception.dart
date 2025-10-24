import '../../core/exception/control_plane_exception.dart';
import '../../control_plane_sdk_error_code.dart';

/// A concrete implementation of the [ControlPlaneException] interface for throwing
/// specific exceptions related to Notify Channel command/operation.
class NotifyChannelException implements ControlPlaneException {
  NotifyChannelException._({
    required this.message,
    required this.code,
    this.innerException,
  });

  /// Creates a `generic` [NotifyChannelException] instance.
  ///
  /// This constructor provides the specific message, error code and the actual
  /// exception encountered in the operation.
  ///
  /// **Parameters:**
  /// - [innerException]: The exception object.
  factory NotifyChannelException.generic({Object? innerException}) {
    return NotifyChannelException._(
      message: 'Notify channel exception: ${innerException.toString()}.',
      code: ControlPlaneSDKErrorCode.notifyChannelGeneric,
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
