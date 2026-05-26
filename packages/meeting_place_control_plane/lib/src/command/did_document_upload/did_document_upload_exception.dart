import '../../control_plane_sdk_error_code.dart';
import '../../core/exception/control_plane_exception.dart';

/// A concrete implementation of the [ControlPlaneException] interface for
/// throwing specific exceptions related to UploadDidDocument
/// command/operation.
class UploadDidDocumentException implements ControlPlaneException {
  UploadDidDocumentException._({
    required this.message,
    required this.code,
    this.innerException,
  });

  /// Creates an `alreadyRegistered` [UploadDidDocumentException] instance.
  ///
  /// Thrown when the server returns HTTP 409 Conflict, meaning a DID Document
  /// for this DID has already been registered.
  factory UploadDidDocumentException.alreadyRegistered() {
    return UploadDidDocumentException._(
      message: 'DID document upload failed: already registered.',
      code: ControlPlaneSDKErrorCode.uploadDidDocumentAlreadyRegistered,
    );
  }

  /// Creates a `generic` [UploadDidDocumentException] instance.
  ///
  /// This constructor provides the specific message, error code and the actual
  /// exception encountered in the operation.
  ///
  /// **Parameters:**
  /// - [innerException]: The exception object.
  factory UploadDidDocumentException.generic({Object? innerException}) {
    return UploadDidDocumentException._(
      message: 'DID document upload failed.',
      code: ControlPlaneSDKErrorCode.uploadDidDocumentGeneric,
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
