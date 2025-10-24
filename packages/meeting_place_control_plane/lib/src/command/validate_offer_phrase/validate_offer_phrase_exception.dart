import '../../core/exception/control_plane_exception.dart';
import '../../control_plane_sdk_error_code.dart';

/// A concrete implementation of the [ControlPlaneException] interface for throwing
/// specific exceptions related to Validate Offer Phrase command/operation.
class ValidateOfferPhraseExceptions implements ControlPlaneException {
  ValidateOfferPhraseExceptions._({
    required this.message,
    required this.code,
    this.innerException,
  });

  /// Creates a `authentication` [ValidateOfferPhraseExceptions] instance.
  ///
  /// This constructor provides the specific message, error code and the actual
  /// exception encountered in the operation.
  ///
  /// **Parameters:**
  /// - [innerException]: The exception object.
  factory ValidateOfferPhraseExceptions.authentication({
    Object? innerException,
  }) {
    return ValidateOfferPhraseExceptions._(
      message: 'Register offer group exception: ${innerException.toString()}.',
      code: ControlPlaneSDKErrorCode.validateOfferPhraseAuthentication,
      innerException: innerException,
    );
  }

  /// Creates a `rateLimit` [ValidateOfferPhraseExceptions] instance.
  ///
  /// This constructor provides the specific message, error code and the actual
  /// exception encountered in the operation.
  ///
  /// **Parameters:**
  /// - [innerException]: The exception object.
  factory ValidateOfferPhraseExceptions.rateLimit({Object? innerException}) {
    return ValidateOfferPhraseExceptions._(
      message: 'Rate limit exceeded for phrase validation',
      code: ControlPlaneSDKErrorCode.validateOfferPhraseRateLimit,
      innerException: innerException,
    );
  }

  /// Creates a `timeout` [ValidateOfferPhraseExceptions] instance.
  ///
  /// This constructor provides the specific message, error code and the actual
  /// exception encountered in the operation.
  ///
  /// **Parameters:**
  /// - [innerException]: The exception object.
  factory ValidateOfferPhraseExceptions.timeout({Object? innerException}) {
    return ValidateOfferPhraseExceptions._(
      message: 'Request timeout during phrase validation',
      code: ControlPlaneSDKErrorCode.validateOfferPhraseTimeout,
      innerException: innerException,
    );
  }

  /// Creates a `generic` [ValidateOfferPhraseExceptions] instance.
  ///
  /// This constructor provides the specific message, error code and the actual
  /// exception encountered in the operation.
  ///
  /// **Parameters:**
  /// - [innerException]: The exception object.
  factory ValidateOfferPhraseExceptions.generic({Object? innerException}) {
    return ValidateOfferPhraseExceptions._(
      message: 'Unexpected error occurred',
      code: ControlPlaneSDKErrorCode.validateOfferPhraseGeneric,
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
