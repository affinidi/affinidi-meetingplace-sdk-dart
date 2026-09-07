import '../../core/exception/control_plane_exception.dart';
import '../../meeting_place_control_plane_sdk_error_code.dart';

/// A concrete implementation of the [ControlPlaneException] interface for
/// throwing
/// specific exceptions related to AcceptOfferGroup command/operation.
class AcceptOfferGroupException implements ControlPlaneException {
  AcceptOfferGroupException._({
    required this.message,
    required this.code,
    this.innerException,
  });

  /// Creates a `generic` error [AcceptOfferGroupException] instance.
  ///
  /// This constructor provides the specific message and error code for the
  /// operation, wrapping the given [innerException].
  factory AcceptOfferGroupException.generic({Object? innerException}) {
    return AcceptOfferGroupException._(
      message: 'Offer acceptance group failed: ${innerException.toString()}.',
      code: MeetingPlaceControlPlaneSDKErrorCode.acceptOfferGroupGeneric,
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
