enum CommandDispatcherExceptionCodes {
  missingHandlerError('command_handler_missing_handler_error');

  const CommandDispatcherExceptionCodes(this.code);

  final String code;
}

class CommandDispatcherException implements Exception {
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
      code: CommandDispatcherExceptionCodes.missingHandlerError,
      innerException: innerException,
    );
  }

  final String message;

  final CommandDispatcherExceptionCodes code;

  final Exception? innerException;
}
