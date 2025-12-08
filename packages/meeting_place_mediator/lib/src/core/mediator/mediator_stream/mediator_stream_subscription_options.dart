import 'package:didcomm/didcomm.dart';

/// Options for subscribing to mediator messages.
class MediatorStreamSubscriptionOptions {
  const MediatorStreamSubscriptionOptions({
    this.deleteMessageDelay = const Duration(milliseconds: 3000),
    this.messageWrappingTypes = const [
      MessageWrappingType.authcryptSignPlaintext
    ],
  });

  /// Delay before deleting messages from the mediator after they have been
  /// processed by listeners on the WebSocket connection. If set to `null`,
  /// messages will be deleted immediately after processing.
  final Duration? deleteMessageDelay;

  /// Types of message wrapping to use when subscribing to mediator messages.
  final List<MessageWrappingType> messageWrappingTypes;
}
