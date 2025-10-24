import 'command.dart';
import 'command_handler.dart';

class CommandDispatcher {
  final Map<Type, CommandHandler> _handlers = {};

  void registerHandler<T extends DiscoveryCommand<R>, R>(
    CommandHandler<T, R> handler,
  ) {
    _handlers[T] = handler;
  }

  Future<R> dispatch<T extends DiscoveryCommand<R>, R>(T command) async {
    final handler = _handlers[command.runtimeType] as CommandHandler<T, R>;
    return handler.handle(command);
  }
}
