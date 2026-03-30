import '../../../meeting_place_mediator.dart';
import '../exception/i_mediator_exception.dart';

class CommandDispatcherException implements IMediatorException {
  CommandDispatcherException({
    required this.message,
    required this.code,
    this.innerException,
  });

  factory CommandDispatcherException.missingHandlerError({
    Exception? innerException,
  }) {
    return CommandDispatcherException(
      message: 'CommandDispatcher Error: No handler registered for command',
      code: MeetingPlaceMediatorSDKErrorCode.missingHandlerError,
      innerException: innerException,
    );
  }

  @override
  final String message;

  @override
  final MeetingPlaceMediatorSDKErrorCode code;

  @override
  final Exception? innerException;
}
