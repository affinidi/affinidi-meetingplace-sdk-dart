import 'incoming_chat_event.dart';

/// Contract for transport-neutral incoming chat event handlers. The transport
/// adapter (e.g., Matrix) routes incoming events to the right handler based
/// on [IncomingChatEvent.type].
abstract interface class ChatEventHandler {
  Future<void> handle(IncomingChatEvent event);
}
