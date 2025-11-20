import '../../control_plane_sdk_error_code.dart';
import '../../core/exception/control_plane_exception.dart';

/// A concrete implementation of the [ControlPlaneException] interface for
/// throwing specific exceptions related to AcceptOfferGroup command/operation.
class AcceptOfferGroupException implements ControlPlaneException {
  AcceptOfferGroupException._({
    required this.message,
    required this.code,
    this.innerException,
  });

  /// Creates a `generic` error of [AcceptOfferGroupException] instance.
  ///
  /// This constructor provides the specific message, error code and the actual
  /// exception encountered in the operation.
  ///
  /// **Parameters:**
  /// - [innerException]: The exception object.
  factory AcceptOfferGroupException.generic({Object? innerException}) {
    return AcceptOfferGroupException._(
      message: 'Offer acceptance group failed: ${innerException.toString()}.',
      code: ControlPlaneSDKErrorCode.acceptOfferGroupGeneric,
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
