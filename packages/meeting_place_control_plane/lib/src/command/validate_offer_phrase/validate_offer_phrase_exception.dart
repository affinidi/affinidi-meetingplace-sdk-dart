import '../../core/exception/control_plane_exception.dart';

/// ValidateOfferPhraseExceptionCodes enum definitions.
enum ValidateOfferPhraseExceptionCodes {
  authentication('validate_offer_phrase_authentication'),
  rateLimit('validate_offer_phrase_rate_limit'),
  timeout('validate_offer_phrase_timeout'),
  generic('validate_offer_phrase_generic');

  const ValidateOfferPhraseExceptionCodes(this.code);
  final String code;
}

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
      code: ValidateOfferPhraseExceptionCodes.authentication,
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
      code: ValidateOfferPhraseExceptionCodes.rateLimit,
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
      code: ValidateOfferPhraseExceptionCodes.timeout,
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
      code: ValidateOfferPhraseExceptionCodes.generic,
      innerException: innerException,
    );
  }
  @override
  final String message;

  final ValidateOfferPhraseExceptionCodes code;

  @override
  final Object? innerException;

  @override
  String get errorCode => code.code;
}
