import '../../core/exception/control_plane_exception.dart';

/// NotifyAcceptanceExceptionCodes enum definitions.
enum NotifyAcceptanceExceptionCodes {
  generic('discovery_notify_acceptance_generic');

  const NotifyAcceptanceExceptionCodes(this.code);
  final String code;
}

/// A concrete implementation of the [ControlPlaneException] interface for throwing
/// specific exceptions related to Notify Acceptance command/operation.
class NotifyAcceptanceException implements ControlPlaneException {
  NotifyAcceptanceException._({
    required this.message,
    required this.code,
    this.innerException,
  });

  /// Creates a `generic` [NotifyAcceptanceException] instance.
  ///
  /// This constructor provides the specific message, error code and the actual
  /// exception encountered in the operation.
  ///
  /// **Parameters:**
  /// - [innerException]: The exception object.
  factory NotifyAcceptanceException.generic({Object? innerException}) {
    return NotifyAcceptanceException._(
      message: 'Notify acceptance exception: ${innerException.toString()}.',
      code: NotifyAcceptanceExceptionCodes.generic,
      innerException: innerException,
    );
  }
  @override
  final String message;

  final NotifyAcceptanceExceptionCodes code;

  @override
  final Object? innerException;

  @override
  String get errorCode => code.code;
}
