import '../../core/exception/control_plane_exception.dart';
import '../../meeting_place_control_plane_sdk_error_code.dart';

/// A concrete implementation of the [ControlPlaneException] interface for
/// throwing
/// specific exceptions related to finalise acceptance command/operation.
class FinaliseAcceptanceException implements ControlPlaneException {
  FinaliseAcceptanceException._({
    required this.message,
    required this.code,
    this.innerException,
  });

  /// Creates a `finaliseAcceptanceError` [FinaliseAcceptanceException]
  /// instance.
  ///
  /// This constructor provides the specific message and error code for the
  /// operation, using the response [statusCode] and [data], and wrapping
  /// the given [innerException].
  factory FinaliseAcceptanceException.finaliseAcceptanceError({
    required int? statusCode,
    required String data,
    Object? innerException,
  }) {
    return FinaliseAcceptanceException._(
      message: 'Finalise acceptance failed: ${innerException.toString()}.',
      code: MeetingPlaceControlPlaneSDKErrorCode.finaliseAcceptanceError,
      innerException: innerException,
    );
  }

  /// Creates a `generic` [FinaliseAcceptanceException] instance.
  ///
  /// This constructor provides the specific message and error code for the
  /// operation, wrapping the given [innerException].
  factory FinaliseAcceptanceException.generic({Object? innerException}) {
    return FinaliseAcceptanceException._(
      message: 'Finalise acceptance failed: ${innerException.toString()}.',
      code: MeetingPlaceControlPlaneSDKErrorCode.finaliseAcceptanceGeneric,
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
