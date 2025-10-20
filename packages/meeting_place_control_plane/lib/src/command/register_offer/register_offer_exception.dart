import '../../core/exception/control_plane_exception.dart';

/// RegisterOfferExceptionCodes enum definitions.
enum RegisterOfferExceptionCodes {
  generic('discovery_register_offer_generic'),
  mediatorNotSet('discovery_register_offer_mediator_not_set');

  const RegisterOfferExceptionCodes(this.code);
  final String code;
}

/// A concrete implementation of the [ControlPlaneException] interface for throwing
/// specific exceptions related to Register Offer command/operation.
class RegisterOfferException implements ControlPlaneException {
  RegisterOfferException._({
    required this.message,
    required this.code,
    this.innerException,
  });

  /// Creates a `generic` [RegisterOfferException] instance.
  ///
  /// This constructor provides the specific message, error code and the actual
  /// exception encountered in the operation.
  ///
  /// **Parameters:**
  /// - [innerException]: The exception object.
  factory RegisterOfferException.generic({Object? innerException}) {
    return RegisterOfferException._(
      message: 'Register offer exception: ${innerException.toString()}.',
      code: RegisterOfferExceptionCodes.generic,
      innerException: innerException,
    );
  }

  /// Creates a `mediatorNotSet` [RegisterOfferException] instance.
  ///
  /// This constructor provides the specific message, error code and the actual
  /// exception encountered in the operation.
  ///
  /// **Parameters:**
  /// - [innerException]: The exception object.
  factory RegisterOfferException.mediatorNotSet() {
    return RegisterOfferException._(
      message: 'Register offer exception: mediator not set.',
      code: RegisterOfferExceptionCodes.mediatorNotSet,
    );
  }
  @override
  final String message;

  final RegisterOfferExceptionCodes code;

  @override
  final Object? innerException;

  @override
  String get errorCode => code.code;
}
