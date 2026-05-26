import 'package:matrix/matrix.dart' as matrix;
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meta/meta.dart';

import '../../../../meeting_place_chat.dart';
import '../../../chat/base_chat_sdk.dart';
import '../matrix_user_id_cache.dart';
import 'chat_effect_handler.dart';
import 'incoming_reaction_state_store.dart';
import 'reaction_handler.dart';
import 'receipt_handler.dart';
import 'redaction_handler.dart';
import 'text_message_handler.dart';
import 'typing_handler.dart';

/// Routes incoming [MatrixRoomEvent]s for a [BaseChatSDK].
///
/// Maintains two parallel dispatch tables:
///   * **Matrix-coupled handlers** — closures over `MatrixRoomEvent`. Used
///     for receipts, reactions, redactions, typing, text messages, etc.,
///     which need transport-specific fields.
///   * **Transport-neutral handlers** ([ChatEventHandler]s) — consume the
///     translated [IncomingChatEvent] and live in `chat/`. Used for
///     application-level chat events that should not know about Matrix.
///
/// Event types that match neither map are silently ignored.
typedef MatrixRoomEventHandler = Future<void> Function(MatrixRoomEvent event);

class IncomingRoomEventRouter {
  IncomingRoomEventRouter({required BaseChatSDK chatSDK})
    : _matrixHandlers = buildBaseHandlers(chatSDK),
      _chatHandlers = const {},
      _didCache = chatSDK.didCache;

  @protected
  IncomingRoomEventRouter.withHandlers({
    required MatrixUserIdCache didCache,
    required Map<String, MatrixRoomEventHandler> matrixHandlers,
    required Map<String, ChatEventHandler> chatHandlers,
  }) : _matrixHandlers = matrixHandlers,
       _chatHandlers = chatHandlers,
       _didCache = didCache;

  /// Common matrix-coupled handler map shared by all chat types.
  @protected
  static Map<String, MatrixRoomEventHandler> buildBaseHandlers(
    BaseChatSDK chatSDK,
  ) {
    final reactionStateStore = IncomingReactionStateStore();
    return {
      'm.receipt': ReceiptHandler(
        chatRepository: chatSDK.chatRepository,
        chatStream: chatSDK.chatStream,
        chatId: chatSDK.chatId,
        serverEventIdToMessageId: chatSDK.serverEventIdToMessageId,
      ).handle,
      matrix.EventTypes.Reaction: ReactionHandler(
        chatRepository: chatSDK.chatRepository,
        chatStream: chatSDK.chatStream,
        chatId: chatSDK.chatId,
        serverEventIdToMessageId: chatSDK.serverEventIdToMessageId,
        reactionStateStore: reactionStateStore,
      ).handle,
      matrix.EventTypes.Redaction: RedactionHandler(
        chatRepository: chatSDK.chatRepository,
        chatStream: chatSDK.chatStream,
        chatId: chatSDK.chatId,
        reactionStateStore: reactionStateStore,
      ).handle,
      'm.typing': TypingHandler(
        didCache: chatSDK.didCache,
        chatStream: chatSDK.chatStream,
        ownDid: chatSDK.did,
        logger: chatSDK.logger,
      ).handle,
      ChatEventTypes.chatEffect: ChatEffectHandler(
        chatStream: chatSDK.chatStream,
      ).handle,
      matrix.EventTypes.Message: TextMessageHandler(
        chatRepository: chatSDK.chatRepository,
        chatStream: chatSDK.chatStream,
        chatId: chatSDK.chatId,
        didCache: chatSDK.didCache,
        logger: chatSDK.logger,
        sendDeliveredReceipt: chatSDK.sendChatDeliveredMessage,
      ).handle,
    };
  }

  final MatrixUserIdCache _didCache;
  final Map<String, MatrixRoomEventHandler> _matrixHandlers;
  final Map<String, ChatEventHandler> _chatHandlers;

  Future<void> route(MatrixRoomEvent event) async {
    final dispatchKey = _translate(event);
    if (dispatchKey == null) return;

    final matrixHandler = _matrixHandlers[dispatchKey];
    if (matrixHandler != null) {
      return matrixHandler(event);
    }

    final chatHandler = _chatHandlers[dispatchKey];
    if (chatHandler == null) return;

    return chatHandler.handle(
      IncomingChatEvent(
        type: dispatchKey,
        senderDid: _didCache.resolve(event.userId),
        content: event.content,
      ),
    );
  }

  /// Translates a Matrix event into a transport-neutral dispatch key, or
  /// returns `null` if the event has no neutral mapping. Matrix-native types
  /// without a translation (e.g. `m.receipt`) pass through unchanged.
  String? _translate(MatrixRoomEvent event) {
    if (event.type == matrix.EventTypes.RoomMember) {
      final membership = event.content['membership'] as String?;
      if (membership == matrix.Membership.join.name) {
        return ChatEventTypes.memberJoined;
      }
      if (membership == matrix.Membership.leave.name) {
        return ChatEventTypes.memberLeft;
      }
      return null;
    }
    return switch (event.type) {
      final t when t == MeetingPlaceProtocol.groupDeletion.value =>
        ChatEventTypes.groupDeletion,
      final t when t == ChatProtocol.chatGroupDetailsUpdate.value =>
        ChatEventTypes.groupDetailsUpdate,
      final t when t == ChatProtocol.chatContactDetailsUpdate.value =>
        ChatEventTypes.contactDetailsUpdate,
      final t when t == ChatProtocol.chatEffect.value =>
        ChatEventTypes.chatEffect,
      _ => event.type,
    };
  }
}
