import 'command.dart';
import 'command_handler.dart';
import 'command_handler_exception.dart';

class CommandDispatcher {
  final Map<Type, MediatorCommandHandler> _handlers = {};

  void registerHandler<T extends MediatorCommand<R>, R>(
    MediatorCommandHandler handler,
  ) {
    _handlers[T] = handler;
  }

  Future<R> dispatch<T extends MediatorCommand<R>, R>(T command) async {
    final handler =
        _handlers[command.runtimeType] as MediatorCommandHandler<T, R>?;

    if (handler == null) {
      throw CommandDispatcherException.missingHandlerError();
    }
    return handler.handle(command);
  }
}
