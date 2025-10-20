import '../../core/exception/control_plane_exception.dart';

/// RegisterOfferGroupExceptionCodes enum definitions.
enum RegisterOfferGroupExceptionCodes {
  generic('discovery_register_offer_group_generic'),
  mediatorNotSet('discovery_register_offer_group_mediator_not_set');

  const RegisterOfferGroupExceptionCodes(this.code);
  final String code;
}

/// A concrete implementation of the [ControlPlaneException] interface for throwing
/// specific exceptions related to Register Offer Group command/operation.
class RegisterOfferGroupException implements ControlPlaneException {
  RegisterOfferGroupException._({
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
  factory RegisterOfferGroupException.generic({Object? innerException}) {
    return RegisterOfferGroupException._(
      message: 'Register offer group exception: ${innerException.toString()}.',
      code: RegisterOfferGroupExceptionCodes.generic,
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
  factory RegisterOfferGroupException.mediatorNotSet() {
    return RegisterOfferGroupException._(
      message: 'Register offer group exception: mediator not set.',
      code: RegisterOfferGroupExceptionCodes.mediatorNotSet,
    );
  }
  @override
  final String message;

  final RegisterOfferGroupExceptionCodes code;

  @override
  final Object? innerException;

  @override
  String get errorCode => code.code;
}
