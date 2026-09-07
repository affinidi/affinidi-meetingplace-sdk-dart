import '../../core/exception/control_plane_exception.dart';
import '../../meeting_place_control_plane_sdk_error_code.dart';

/// A concrete implementation of the [ControlPlaneException] interface for
/// throwing
/// specific exceptions related to deregister offer command/operation.
class DeregisterOfferException implements ControlPlaneException {
  DeregisterOfferException._({
    required this.message,
    required this.code,
    this.innerException,
  });

  /// Creates a `deregisterFailedError` [DeregisterOfferException] instance.
  ///
  /// This constructor provides the specific message and error code for the
  /// operation, using the response [statusCode] and [data], and wrapping
  /// the given [innerException].
  factory DeregisterOfferException.deregisterFailedError({
    required int? statusCode,
    required String data,
    Object? innerException,
  }) {
    return DeregisterOfferException._(
      message:
          '''Deregister offer failed: ${innerException.toString()}, status code: $statusCode, data: $data''',
      code: MeetingPlaceControlPlaneSDKErrorCode.deregisterOfferFailedError,
      innerException: innerException,
    );
  }

  /// Creates a `generic` [DeregisterOfferException] instance.
  ///
  /// This constructor provides the specific message and error code for the
  /// operation, wrapping the given [innerException].
  factory DeregisterOfferException.generic({Object? innerException}) {
    return DeregisterOfferException._(
      message: 'Deregister offer failed: ${innerException.toString()}.',
      code: MeetingPlaceControlPlaneSDKErrorCode.deregisterOfferGeneric,
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
