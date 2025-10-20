import '../../core/exception/control_plane_exception.dart';

/// AcceptOfferExceptionCodes enum definitions.
enum AcceptOfferExceptionCodes {
  limitExceeded('discovery_accept_offer_limit_exceeded'),
  alreadyAccepted('discovery_accept_offer_already_accepted'),
  generic('discovery_accept_offer_generic');

  const AcceptOfferExceptionCodes(this.code);
  final String code;
}

/// A concrete implementation of the [ControlPlaneException] interface for throwing
/// specific exceptions related to AcceptOffer command/operation.
class AcceptOfferException implements ControlPlaneException {
  AcceptOfferException._({
    required this.message,
    required this.code,
    this.innerException,
  });

  /// Creates a `limitExceededError` [AcceptOfferException] instance.
  ///
  /// This constructor provides the specific message, error code and the actual
  /// exception encountered in the operation.
  ///
  /// **Parameters:**
  /// - [innerException]: The exception object.
  factory AcceptOfferException.limitExceededError({Object? innerException}) {
    return AcceptOfferException._(
      message:
          '''Offer acceptance failed: the maximum number of allowed offer usages has been reached.''',
      code: AcceptOfferExceptionCodes.limitExceeded,
      innerException: innerException,
    );
  }

  /// Creates a `alreadyAcceptedError` [AcceptOfferException] instance.
  ///
  /// This constructor provides the specific message, error code and the actual
  /// exception encountered in the operation.
  ///
  /// **Parameters:**
  /// - [innerException]: The exception object.
  factory AcceptOfferException.alreadyAcceptedError({Object? innerException}) {
    return AcceptOfferException._(
      message: 'Offer acceptance failed: offer has already been accepted.',
      code: AcceptOfferExceptionCodes.alreadyAccepted,
      innerException: innerException,
    );
  }

  /// Creates a `generic` [AcceptOfferException] instance.
  ///
  /// This constructor provides the specific message, error code and the actual
  /// exception encountered in the operation.
  ///
  /// **Parameters:**
  /// - [innerException]: The exception object.
  factory AcceptOfferException.generic({Object? innerException}) {
    return AcceptOfferException._(
      message: 'Offer acceptance failed: ${innerException.toString()}.',
      code: AcceptOfferExceptionCodes.generic,
      innerException: innerException,
    );
  }
  @override
  final String message;

  final AcceptOfferExceptionCodes code;

  @override
  final Object? innerException;

  @override
  String get errorCode => code.code;
}
