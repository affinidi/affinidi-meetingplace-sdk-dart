import '../../core/exception/control_plane_exception.dart';

/// FinaliseAcceptanceExceptionCodes enum definitions.
enum FinaliseAcceptanceExceptionCodes {
  generic('discovery_finalise_acceptande_generic'),
  finaliseAcceptanceError('discovery_finalise_acceptance_error');

  const FinaliseAcceptanceExceptionCodes(this.code);
  final String code;
}

/// A concrete implementation of the [ControlPlaneException] interface for throwing
/// specific exceptions related to finalise acceptance command/operation.
class FinaliseAcceptanceException implements ControlPlaneException {
  FinaliseAcceptanceException._({
    required this.message,
    required this.code,
    this.innerException,
  });

  /// Creates a `finaliseAcceptanceError` [FinaliseAcceptanceException] instance.
  ///
  /// This constructor provides the specific message, error code and the actual
  /// exception encountered in the operation.
  ///
  /// **Parameters:**
  /// - [innerException]: The exception object.
  factory FinaliseAcceptanceException.finaliseAcceptanceError({
    required int? statusCode,
    required String data,
    Object? innerException,
  }) {
    return FinaliseAcceptanceException._(
      message: 'Finalise acceptance failed: ${innerException.toString()}.',
      code: FinaliseAcceptanceExceptionCodes.finaliseAcceptanceError,
      innerException: innerException,
    );
  }

  /// Creates a `generic` [FinaliseAcceptanceException] instance.
  ///
  /// This constructor provides the specific message, error code and the actual
  /// exception encountered in the operation.
  ///
  /// **Parameters:**
  /// - [innerException]: The exception object.
  factory FinaliseAcceptanceException.generic({Object? innerException}) {
    return FinaliseAcceptanceException._(
      message: 'Finalise acceptance failed: ${innerException.toString()}.',
      code: FinaliseAcceptanceExceptionCodes.generic,
      innerException: innerException,
    );
  }
  @override
  final String message;

  final FinaliseAcceptanceExceptionCodes code;

  @override
  final Object? innerException;

  @override
  String get errorCode => code.code;
}
