import '../../control_plane_sdk_error_code.dart';
import '../../core/exception/control_plane_exception.dart';

/// A concrete implementation of the [ControlPlaneException] interface for
/// throwing specific exceptions related to ValidateOfferPhrase
/// command/operation.
class ValidateOfferPhraseException implements ControlPlaneException {
  ValidateOfferPhraseException._({
    required this.message,
    required this.code,
    this.innerException,
  });

  /// Creates a `authentication` [ValidateOfferPhraseException] instance.
  ///
  /// This constructor provides the specific message, error code and the actual
  /// exception encountered in the operation.
  ///
  /// **Parameters:**
  /// - [innerException]: The exception object.
  factory ValidateOfferPhraseException.authentication({
    Object? innerException,
  }) {
    return ValidateOfferPhraseException._(
      message: 'Register offer group exception: ${innerException.toString()}.',
      code: ControlPlaneSDKErrorCode.validateOfferPhraseAuthentication,
      innerException: innerException,
    );
  }

  /// Creates a `rateLimit` [ValidateOfferPhraseException] instance.
  ///
  /// This constructor provides the specific message, error code and the actual
  /// exception encountered in the operation.
  ///
  /// **Parameters:**
  /// - [innerException]: The exception object.
  factory ValidateOfferPhraseException.rateLimit({Object? innerException}) {
    return ValidateOfferPhraseException._(
      message: 'Rate limit exceeded for phrase validation',
      code: ControlPlaneSDKErrorCode.validateOfferPhraseRateLimit,
      innerException: innerException,
    );
  }

  /// Creates a `timeout` [ValidateOfferPhraseException] instance.
  ///
  /// This constructor provides the specific message, error code and the actual
  /// exception encountered in the operation.
  ///
  /// **Parameters:**
  /// - [innerException]: The exception object.
  factory ValidateOfferPhraseException.timeout({Object? innerException}) {
    return ValidateOfferPhraseException._(
      message: 'Request timeout during phrase validation',
      code: ControlPlaneSDKErrorCode.validateOfferPhraseTimeout,
      innerException: innerException,
    );
  }

  /// Creates a `generic` [ValidateOfferPhraseException] instance.
  ///
  /// This constructor provides the specific message, error code and the actual
  /// exception encountered in the operation.
  ///
  /// **Parameters:**
  /// - [innerException]: The exception object.
  factory ValidateOfferPhraseException.generic({Object? innerException}) {
    return ValidateOfferPhraseException._(
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
