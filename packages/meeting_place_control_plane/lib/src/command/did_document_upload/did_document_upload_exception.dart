import '../../control_plane_sdk_error_code.dart';
import '../../core/exception/control_plane_exception.dart';

/// A concrete implementation of the [ControlPlaneException] interface for
/// throwing specific exceptions related to UploadDidWebDocument
/// command/operation.
class UploadDidWebDocumentException implements ControlPlaneException {
  UploadDidWebDocumentException._({
    required this.message,
    required this.code,
    this.innerException,
  });

  /// Creates an `alreadyRegistered` [UploadDidWebDocumentException] instance.
  ///
  /// Thrown when the server returns HTTP 409 Conflict, meaning a DID Document
  /// for this DID has already been registered.
  factory UploadDidWebDocumentException.alreadyRegistered() {
    return UploadDidWebDocumentException._(
      message: 'DID document upload failed: already registered.',
      code: ControlPlaneSDKErrorCode.uploadDidWebDocumentAlreadyRegistered,
    );
  }

  /// Creates a `generic` [UploadDidWebDocumentException] instance.
  ///
  /// This constructor provides the specific message, error code and the actual
  /// exception encountered in the operation.
  ///
  /// **Parameters:**
  /// - [innerException]: The exception object.
  factory UploadDidWebDocumentException.generic({Object? innerException}) {
    return UploadDidWebDocumentException._(
      message: 'DID document upload failed.',
      code: ControlPlaneSDKErrorCode.uploadDidWebDocumentGeneric,
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
