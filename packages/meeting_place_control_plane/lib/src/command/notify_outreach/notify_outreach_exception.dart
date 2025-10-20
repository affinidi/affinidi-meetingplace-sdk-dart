import '../../core/exception/control_plane_exception.dart';

enum NotifyChannelExceptionCodes {
  generic('discovery_notify_channel_generic');

  const NotifyChannelExceptionCodes(this.code);
  final String code;
}

class NotifyChannelException implements ControlPlaneException {
  NotifyChannelException({
    required this.message,
    required this.code,
    this.innerException,
  });

  factory NotifyChannelException.generic({Object? innerException}) {
    return NotifyChannelException(
      message: 'Notify outreach exception: ${innerException.toString()}.',
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
