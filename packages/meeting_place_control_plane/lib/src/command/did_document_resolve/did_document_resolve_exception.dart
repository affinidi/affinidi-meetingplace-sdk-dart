import '../../control_plane_sdk_error_code.dart';
import '../../core/exception/control_plane_exception.dart';

/// A concrete implementation of the [ControlPlaneException] interface for
/// throwing specific exceptions related to ResolveDidWebDocument
/// command/operation.
class ResolveDidWebDocumentException implements ControlPlaneException {
  ResolveDidWebDocumentException._({
    required this.message,
    required this.code,
    this.innerException,
  });

  /// Creates an `invalidDid` [ResolveDidWebDocumentException] instance.
  ///
  /// This constructor provides the specific message, error code and the actual
  /// exception encountered in the operation.
  ///
  /// **Parameters:**
  /// - [did]: The invalid DID string that was provided.
  factory ResolveDidWebDocumentException.invalidDid({required String did}) {
    return ResolveDidWebDocumentException._(
      message: 'DID document resolution failed: invalid did:web DID: $did.',
      code: ControlPlaneSDKErrorCode.resolveDidWebDocumentInvalidDid,
    );
  }

  /// Creates a `generic` [ResolveDidWebDocumentException] instance.
  ///
  /// This constructor provides the specific message, error code and the actual
  /// exception encountered in the operation.
  ///
  /// **Parameters:**
  /// - [innerException]: The exception object.
  factory ResolveDidWebDocumentException.generic({Object? innerException}) {
    return ResolveDidWebDocumentException._(
      message: 'DID document resolution failed: ${innerException.toString()}.',
      code: ControlPlaneSDKErrorCode.resolveDidWebDocumentGeneric,
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
