import 'package:matrix/matrix.dart' as matrix;
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meta/meta.dart';

import '../../meeting_place_chat.dart';
import 'base_chat_sdk.dart';
import 'room_event_handler/chat_effect_handler.dart';
import 'room_event_handler/incoming_reaction_state_store.dart';
import 'room_event_handler/reaction_handler.dart';
import 'room_event_handler/receipt_handler.dart';
import 'room_event_handler/redaction_handler.dart';
import 'room_event_handler/room_event_handler.dart';
import 'room_event_handler/text_message_handler.dart';
import 'room_event_handler/typing_handler.dart';

/// Routes incoming [MatrixRoomEvent]s for a [BaseChatSDK] to the correct
/// [RoomEventHandler] based on event type. Event types not in the handler
/// map are silently ignored.
class IncomingRoomEventRouter {
  IncomingRoomEventRouter({required BaseChatSDK chatSDK})
    : _handlers = buildBaseHandlers(chatSDK);

  @protected
  IncomingRoomEventRouter.withHandlers(Map<String, RoomEventHandler> handlers)
    : _handlers = handlers;

  /// Common handler map shared by all chat types. Subclasses can spread this
  /// and add their own entries before passing it to [withHandlers].
  @protected
  static Map<String, RoomEventHandler> buildBaseHandlers(BaseChatSDK chatSDK) {
    final reactionStateStore = IncomingReactionStateStore();
    return {
      'm.receipt': ReceiptHandler(
        chatRepository: chatSDK.chatRepository,
        chatStream: chatSDK.chatStream,
        chatId: chatSDK.chatId,
        serverEventIdToMessageId: chatSDK.serverEventIdToMessageId,
      ),
      matrix.EventTypes.Reaction: ReactionHandler(
        chatRepository: chatSDK.chatRepository,
        chatStream: chatSDK.chatStream,
        chatId: chatSDK.chatId,
        serverEventIdToMessageId: chatSDK.serverEventIdToMessageId,
        reactionStateStore: reactionStateStore,
      ),
      matrix.EventTypes.Redaction: RedactionHandler(
        chatRepository: chatSDK.chatRepository,
        chatStream: chatSDK.chatStream,
        chatId: chatSDK.chatId,
        reactionStateStore: reactionStateStore,
      ),
      'm.typing': TypingHandler(
        didCache: chatSDK.didCache,
        chatStream: chatSDK.chatStream,
        ownDid: chatSDK.did,
        logger: chatSDK.logger,
      ),
      ChatProtocol.chatEffect.value: ChatEffectHandler(
        chatStream: chatSDK.chatStream,
      ),
      matrix.EventTypes.Message: TextMessageHandler(
        chatRepository: chatSDK.chatRepository,
        chatStream: chatSDK.chatStream,
        chatId: chatSDK.chatId,
        didCache: chatSDK.didCache,
        logger: chatSDK.logger,
        sendDeliveredReceipt: chatSDK.sendChatDeliveredMessage,
      ),
    };
  }

  final Map<String, RoomEventHandler> _handlers;

  Future<void> route(MatrixRoomEvent event) async {
    final handler = _handlers[event.type];
    if (handler == null) return;
    return handler.handle(event);
  }
}
