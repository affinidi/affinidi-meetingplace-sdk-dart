import '../../control_plane_sdk_error_code.dart';
import '../../core/exception/control_plane_exception.dart';

/// A concrete implementation of the [ControlPlaneException] interface for
/// throwing specific exceptions related to FinaliseAcceptance
/// command/operation.
class FinaliseAcceptanceException implements ControlPlaneException {
  FinaliseAcceptanceException._({
    required this.message,
    required this.code,
    this.innerException,
  });

  /// Creates a `finaliseAcceptanceError` [FinaliseAcceptanceException]
  /// instance.
  ///
  /// This constructor provides the specific message, error code and the actual
  /// exception encountered in the operation.
  ///
  /// **Parameters:**
  /// - [innerException]: The exception object.
  factory FinaliseAcceptanceException.finaliseAcceptanceError({
    required int? statusCode,
    required String data,
    Object? innerException,
  }) {
    return FinaliseAcceptanceException._(
      message: 'Finalise acceptance failed: ${innerException.toString()}.',
      code: ControlPlaneSDKErrorCode.finaliseAcceptanceError,
      innerException: innerException,
    );
  }

  /// Creates a `generic` [FinaliseAcceptanceException] instance.
  ///
  /// This constructor provides the specific message, error code and the actual
  /// exception encountered in the operation.
  ///
  /// **Parameters:**
  /// - [innerException]: The exception object.
  factory FinaliseAcceptanceException.generic({Object? innerException}) {
    return FinaliseAcceptanceException._(
      message: 'Finalise acceptance failed: ${innerException.toString()}.',
      code: ControlPlaneSDKErrorCode.finaliseAcceptanceGeneric,
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
