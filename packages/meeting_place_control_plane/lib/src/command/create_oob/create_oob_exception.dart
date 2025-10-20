import '../../core/exception/control_plane_exception.dart';

/// CreateOobExceptionCodes enum definitions.
enum CreateOobExceptionCodes {
  generic('discovery_create_oob_generic');

  const CreateOobExceptionCodes(this.code);
  final String code;
}

/// A concrete implementation of the [ControlPlaneException] interface for throwing
/// specific exceptions related to Create Out-Of-Band command/operation.
class CreateOobException implements ControlPlaneException {
  CreateOobException._({
    required this.message,
    required this.code,
    this.innerException,
  });

  /// Creates a `generic` [CreateOobException] instance.
  ///
  /// This constructor provides the specific message, error code and the actual
  /// exception encountered in the operation.
  ///
  /// **Parameters:**
  /// - [innerException]: The exception object.
  factory CreateOobException.generic({Object? innerException}) {
    return CreateOobException._(
      message: 'Create oob exception: ${innerException.toString()}.',
      code: CreateOobExceptionCodes.generic,
      innerException: innerException,
    );
  }
  @override
  final String message;

  final CreateOobExceptionCodes code;

  @override
  final Object? innerException;

  @override
  String get errorCode => code.code;
}
