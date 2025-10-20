import '../../core/exception/control_plane_exception.dart';

/// NotifyChannelExceptionCodes enum definitions.
enum NotifyChannelExceptionCodes {
  generic('discovery_notify_channel_generic');

  const NotifyChannelExceptionCodes(this.code);
  final String code;
}

/// A concrete implementation of the [ControlPlaneException] interface for throwing
/// specific exceptions related to Notify Channel command/operation.
class NotifyChannelException implements ControlPlaneException {
  NotifyChannelException._({
    required this.message,
    required this.code,
    this.innerException,
  });

  /// Creates a `generic` [NotifyChannelException] instance.
  ///
  /// This constructor provides the specific message, error code and the actual
  /// exception encountered in the operation.
  ///
  /// **Parameters:**
  /// - [innerException]: The exception object.
  factory NotifyChannelException.generic({Object? innerException}) {
    return NotifyChannelException._(
      message: 'Notify channel exception: ${innerException.toString()}.',
      code: NotifyChannelExceptionCodes.generic,
      innerException: innerException,
    );
  }
  @override
  final String message;

  final NotifyChannelExceptionCodes code;

  @override
  final Object? innerException;

  @override
  String get errorCode => code.code;
}
