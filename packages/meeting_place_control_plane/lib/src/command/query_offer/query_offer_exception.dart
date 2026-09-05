import '../../core/exception/control_plane_exception.dart';
import '../../meeting_place_control_plane_sdk_error_code.dart';

/// A concrete implementation of the [ControlPlaneException] interface for
/// throwing
/// specific exceptions related to Query Offer command/operation.
class QueryOfferException implements ControlPlaneException {
  QueryOfferException._({
    required this.message,
    required this.code,
    this.innerException,
  });

  /// Creates a `generic` [QueryOfferException] instance.
  ///
  /// This constructor provides the specific message, error code and the actual
  /// exception encountered in the operation.
  ///
  /// **Parameters:**
  /// - [innerException]: The exception object.
  factory QueryOfferException.generic({Object? innerException}) {
    return QueryOfferException._(
      message: 'Query offer exception: ${innerException.toString()}.',
      code: MeetingPlaceControlPlaneSDKErrorCode.queryOfferOfferGeneric,
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
