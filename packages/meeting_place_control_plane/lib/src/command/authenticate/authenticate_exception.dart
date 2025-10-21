import '../../core/exception/control_plane_exception.dart';
import '../../control_plane_sdk_error_code.dart';
import '../../utils/string.dart';

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
      code: ControlPlaneSDKErrorCode.authenticateEmptyChallengeReturned,
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
      code: ControlPlaneSDKErrorCode.authenticateGeneric,
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
      code: ControlPlaneSDKErrorCode.authenticateInvalidResponseData,
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
