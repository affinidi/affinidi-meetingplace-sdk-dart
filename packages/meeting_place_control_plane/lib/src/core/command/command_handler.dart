import 'command.dart';

abstract class CommandHandler<T extends DiscoveryCommand<R>, R> {
  Future<R> handle(T command);
}
