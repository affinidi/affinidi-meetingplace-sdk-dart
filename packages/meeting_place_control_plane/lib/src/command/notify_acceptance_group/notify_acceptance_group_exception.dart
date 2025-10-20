import '../../core/exception/control_plane_exception.dart';

/// NotifyAcceptanceGroupExceptionCodes enum definitions.
enum NotifyAcceptanceGroupExceptionCodes {
  generic('discovery_notify_acceptance_group_generic');

  const NotifyAcceptanceGroupExceptionCodes(this.code);
  final String code;
}

/// A concrete implementation of the [ControlPlaneException] interface for throwing
/// specific exceptions related to Notify Acceptance group command/operation.
class NotifyAcceptanceGroupException implements ControlPlaneException {
  NotifyAcceptanceGroupException._({
    required this.message,
    required this.code,
    this.innerException,
  });

  /// Creates a `generic` [NotifyAcceptanceGroupException] instance.
  ///
  /// This constructor provides the specific message, error code and the actual
  /// exception encountered in the operation.
  ///
  /// **Parameters:**
  /// - [innerException]: The exception object.
  factory NotifyAcceptanceGroupException.generic({Object? innerException}) {
    return NotifyAcceptanceGroupException._(
      message:
          'Notify acceptance group exception: ${innerException.toString()}.',
      code: NotifyAcceptanceGroupExceptionCodes.generic,
      innerException: innerException,
    );
  }
  @override
  final String message;

  final NotifyAcceptanceGroupExceptionCodes code;

  @override
  final Object? innerException;

  @override
  String get errorCode => code.code;
}
