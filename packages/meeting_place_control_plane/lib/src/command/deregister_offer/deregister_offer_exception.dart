import '../../control_plane_sdk_error_code.dart';
import '../../core/exception/control_plane_exception.dart';

/// A concrete implementation of the [ControlPlaneException] interface for
/// throwing specific exceptions related to DeregisterOffer command/operation.
class DeregisterOfferException implements ControlPlaneException {
  DeregisterOfferException._({
    required this.message,
    required this.code,
    this.innerException,
  });

  /// Creates a `deregisterFailedError` [DeregisterOfferException] instance.
  ///
  /// This constructor provides the specific message, error code and the actual
  /// exception encountered in the operation.
  ///
  /// **Parameters:**
  /// - [innerException]: The exception object.
  factory DeregisterOfferException.deregisterFailedError({
    required int? statusCode,
    required String data,
    Object? innerException,
  }) {
    return DeregisterOfferException._(
      message:
          '''Deregister offer failed: ${innerException.toString()}, status code: $statusCode, data: $data''',
      code: ControlPlaneSDKErrorCode.deregisterOfferFailedError,
      innerException: innerException,
    );
  }

  /// Creates a `generic` [DeregisterOfferException] instance.
  ///
  /// This constructor provides the specific message, error code and the actual
  /// exception encountered in the operation.
  ///
  /// **Parameters:**
  /// - [innerException]: The exception object.
  factory DeregisterOfferException.generic({Object? innerException}) {
    return DeregisterOfferException._(
      message: 'Deregister offer failed: ${innerException.toString()}.',
      code: ControlPlaneSDKErrorCode.deregisterOfferGeneric,
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
