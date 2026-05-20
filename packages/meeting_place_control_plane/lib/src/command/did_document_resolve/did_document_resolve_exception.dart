import '../../control_plane_sdk_error_code.dart';
import '../../core/exception/control_plane_exception.dart';

/// A concrete implementation of the [ControlPlaneException] interface for
/// throwing specific exceptions related to ResolveDidDocument
/// command/operation.
class ResolveDidDocumentException implements ControlPlaneException {
  ResolveDidDocumentException._({
    required this.message,
    required this.code,
    this.innerException,
  });

  /// Creates an `invalidDid` [ResolveDidDocumentException] instance.
  ///
  /// This constructor provides the specific message, error code and the actual
  /// exception encountered in the operation.
  ///
  /// **Parameters:**
  /// - [did]: The invalid DID string that was provided.
  factory ResolveDidDocumentException.invalidDid({required String did}) {
    return ResolveDidDocumentException._(
      message: 'DID document resolution failed: invalid did:web DID: $did.',
      code: ControlPlaneSDKErrorCode.resolveDidDocumentInvalidDid,
    );
  }

  /// Creates a `generic` [ResolveDidDocumentException] instance.
  ///
  /// This constructor provides the specific message, error code and the actual
  /// exception encountered in the operation.
  ///
  /// **Parameters:**
  /// - [innerException]: The exception object.
  factory ResolveDidDocumentException.generic({Object? innerException}) {
    return ResolveDidDocumentException._(
      message: 'DID document resolution failed: ${innerException.toString()}.',
      code: ControlPlaneSDKErrorCode.resolveDidDocumentGeneric,
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
