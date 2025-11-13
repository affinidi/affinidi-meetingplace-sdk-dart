import '../../core/exception/control_plane_exception.dart';
import '../../control_plane_sdk_error_code.dart';

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
      code: ControlPlaneSDKErrorCode.registerOfferGeneric,
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
      code: ControlPlaneSDKErrorCode.registerOfferMediatorNotSet,
    );
  }

  /// Creates a `mnemonicInUse` [RegisterOfferException] instance.
  ///
  /// This constructor provides the specific message, error code and the actual
  /// exception encountered in the operation.
  ///
  /// **Parameters:**
  /// - [innerException]: The exception object.
  factory RegisterOfferException.mnemonicInUse() {
    return RegisterOfferException._(
      message:
          'Register offer exception: Offer with the same mnemonic already exists.',
      code: ControlPlaneSDKErrorCode.registerOfferMnemonicInUse,
    );
  }

  @override
  final String message;

  @override
  final ControlPlaneSDKErrorCode code;

  @override
  final Object? innerException;
}
