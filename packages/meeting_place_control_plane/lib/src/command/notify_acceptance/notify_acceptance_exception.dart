import '../../control_plane_sdk_error_code.dart';
import '../../core/exception/control_plane_exception.dart';

/// A concrete implementation of the [ControlPlaneException] interface for
/// throwing specific exceptions related to NotifyAcceptance command/operation.
class NotifyAcceptanceException implements ControlPlaneException {
  NotifyAcceptanceException._({
    required this.message,
    required this.code,
    this.innerException,
  });

  /// Creates a `generic` [NotifyAcceptanceException] instance.
  ///
  /// This constructor provides the specific message, error code and the actual
  /// exception encountered in the operation.
  ///
  /// **Parameters:**
  /// - [innerException]: The exception object.
  factory NotifyAcceptanceException.generic({Object? innerException}) {
    return NotifyAcceptanceException._(
      message: 'Notify acceptance exception: ${innerException.toString()}.',
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
