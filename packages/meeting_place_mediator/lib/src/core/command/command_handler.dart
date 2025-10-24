import 'command.dart';

abstract class MediatorCommandHandler<T extends MediatorCommand<R>, R> {
  Future<R> handle(T command);
}
