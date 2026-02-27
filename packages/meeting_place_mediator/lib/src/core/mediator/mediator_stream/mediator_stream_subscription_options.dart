import 'package:didcomm/didcomm.dart';

/// Options for subscribing to mediator messages.
class MediatorStreamSubscriptionOptions {
  const MediatorStreamSubscriptionOptions({
    this.deleteMessageDelay = const Duration(milliseconds: 3000),
    this.expectedMessageWrappingTypes = const [
      MessageWrappingType.authcryptSignPlaintext,
    ],
    this.fetchMessagesOnConnect = true,
  });

  /// Default options instance
  static const defaults = MediatorStreamSubscriptionOptions();

  /// Delay before deleting messages from the mediator after they have been
  /// processed by listeners on the WebSocket connection. If set to `null`,
  /// messages will be deleted immediately after processing.
  final Duration? deleteMessageDelay;

  /// Expected message wrapping types for unpacking DIDComm messages.
  ///
  /// Defaults to [MessageWrappingType.authcryptSignPlaintext]
  ///
  /// Set to both [MessageWrappingType.authcryptPlaintext] and
  /// [MessageWrappingType.authcryptSignPlaintext] if using multiple protocols
  /// (e.g., chat + VDIP) that use different message signing configurations.
  final List<MessageWrappingType> expectedMessageWrappingTypes;

  /// Whether to fetch messages from the mediator when the WebSocket
  /// connection is established.
  final bool fetchMessagesOnConnect;
}
