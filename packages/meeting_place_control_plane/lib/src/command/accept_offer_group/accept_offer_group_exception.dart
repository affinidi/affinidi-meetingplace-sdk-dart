import '../../core/exception/control_plane_exception.dart';

/// AcceptOfferGroupExceptionCodes enum definitions.
enum AcceptOfferGroupExceptionCodes {
  generic('discovery_accept_offer_group_generic');

  const AcceptOfferGroupExceptionCodes(this.code);
  final String code;
}

/// A concrete implementation of the [ControlPlaneException] interface for throwing
/// specific exceptions related to AcceptOfferGroup command/operation.
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
      code: AcceptOfferGroupExceptionCodes.generic,
      innerException: innerException,
    );
  }
  @override
  final String message;

  final AcceptOfferGroupExceptionCodes code;

  @override
  final Object? innerException;

  @override
  String get errorCode => code.code;
}
