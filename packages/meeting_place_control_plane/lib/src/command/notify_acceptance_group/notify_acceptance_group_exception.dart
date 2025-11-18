import '../../control_plane_sdk_error_code.dart';
import '../../core/exception/control_plane_exception.dart';

/// A concrete implementation of the [ControlPlaneException] interface for
/// throwing specific exceptions related to NotifyAcceptanceGroup
/// command/operation.
class NotifyAcceptanceGroupException implements ControlPlaneException {
  NotifyAcceptanceGroupException._({
    required this.message,
    required this.code,
    this.innerException,
  });

  /// Creates a `generic` [NotifyAcceptanceGroupException] instance.
  ///
  /// This constructor provides the specific message, error code and the actual
  /// exception encountered in the operation.
  ///
  /// **Parameters:**
  /// - [innerException]: The exception object.
  factory NotifyAcceptanceGroupException.generic({Object? innerException}) {
    return NotifyAcceptanceGroupException._(
      message:
          'Notify acceptance group exception: ${innerException.toString()}.',
      code: ControlPlaneSDKErrorCode.notifyAcceptanceGeneric,
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
