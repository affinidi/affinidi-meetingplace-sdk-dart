import '../../core/exception/control_plane_exception.dart';
import '../../utils/string.dart';

/// AuthenticateExceptionCodes enum definitions.
enum AuthenticateExceptionCodes {
  generic('discovery_authenticate_generic'),
  emptyChallengeReturned('discovery_authenticate_empty_challenge_returned'),
  invalidResponseData('discovery_invalid_response_data');

  const AuthenticateExceptionCodes(this.code);
  final String code;
}

/// A concrete implementation of the [ControlPlaneException] interface for throwing
/// specific exceptions related to Authenticate command/operation.
class AuthenticateException implements ControlPlaneException {
  AuthenticateException._({
    required this.message,
    required this.code,
    this.innerException,
  });

  /// Creates `emptyChallengeReturned` [AuthenticateException] instance.
  ///
  /// This constructor provides the specific message, error code and the actual
  /// exception encountered in the operation.
  ///
  /// **Parameters:**
  /// - [innerException]: The exception object.
  factory AuthenticateException.emptyChallengeReturned({
    required String did,
    Object? innerException,
  }) {
    return AuthenticateException._(
      message:
          'Authentication returned empty challenge for ${did.topAndTail()}',
      code: AuthenticateExceptionCodes.emptyChallengeReturned,
      innerException: innerException,
    );
  }

  /// Creates `generic` error [AuthenticateException] instance.
  ///
  /// This constructor provides the specific message, error code and the actual
  /// exception encountered in the operation.
  ///
  /// **Parameters:**
  /// - [innerException]: The exception object.
  factory AuthenticateException.generic({Object? innerException}) {
    return AuthenticateException._(
      message: 'Authentication failed: ${innerException.toString()}.',
      code: AuthenticateExceptionCodes.generic,
      innerException: innerException,
    );
  }

  /// Creates `invalidResponseData` error [AuthenticateException] instance.
  ///
  /// This constructor provides the specific message, error code and the actual
  /// exception encountered in the operation.
  ///
  /// **Parameters:**
  /// - [innerException]: The exception object.
  factory AuthenticateException.invalidResponseData({
    required String message,
    Object? innerException,
  }) {
    return AuthenticateException._(
      message: 'Authentication failed: $message.',
      code: AuthenticateExceptionCodes.invalidResponseData,
      innerException: innerException,
    );
  }
  @override
  final String message;

  final AuthenticateExceptionCodes code;

  @override
  final Object? innerException;

  @override
  String get errorCode => code.code;
}
