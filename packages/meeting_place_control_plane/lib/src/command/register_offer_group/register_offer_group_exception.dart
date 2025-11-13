import '../../core/exception/control_plane_exception.dart';
import '../../control_plane_sdk_error_code.dart';

/// A concrete implementation of the [ControlPlaneException] interface for throwing
/// specific exceptions related to Register Offer Group command/operation.
class RegisterOfferGroupException implements ControlPlaneException {
  RegisterOfferGroupException._({
    required this.message,
    required this.code,
    this.innerException,
  });

  /// Creates a `generic` [RegisterOfferGroupException] instance.
  ///
  /// This constructor provides the specific message, error code and the actual
  /// exception encountered in the operation.
  ///
  /// **Parameters:**
  /// - [innerException]: The exception object.
  factory RegisterOfferGroupException.generic({Object? innerException}) {
    return RegisterOfferGroupException._(
      message: 'Register offer group exception: ${innerException.toString()}.',
      code: ControlPlaneSDKErrorCode.registerOfferGroupGeneric,
      innerException: innerException,
    );
  }

  /// Creates a `mediatorNotSet` [RegisterOfferGroupException] instance.
  ///
  /// This constructor provides the specific message, error code and the actual
  /// exception encountered in the operation.
  ///
  /// **Parameters:**
  /// - [innerException]: The exception object.
  factory RegisterOfferGroupException.mediatorNotSet() {
    return RegisterOfferGroupException._(
      message: 'Register offer group exception: mediator not set.',
      code: ControlPlaneSDKErrorCode.registerOfferGroupMediatorNotSet,
    );
  }

  /// Creates a `mnemonicInUse` [RegisterOfferGroupException] instance.
  ///
  /// This constructor provides the specific message, error code and the actual
  /// exception encountered in the operation.
  ///
  /// **Parameters:**
  /// - [innerException]: The exception object.
  factory RegisterOfferGroupException.mnemonicInUse() {
    return RegisterOfferGroupException._(
      message:
          'Register offer group exception: Offer with the same mnemonic already exists.',
      code: ControlPlaneSDKErrorCode.registerOfferGroupMnemonicInUse,
    );
  }

  @override
  final String message;

  @override
  final ControlPlaneSDKErrorCode code;

  @override
  final Object? innerException;
}
