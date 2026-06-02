import 'package:matrix/matrix.dart' as matrix;
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meta/meta.dart';

import '../../../../meeting_place_chat.dart';
import '../../../chat/matrix_chat_sdk.dart';
import 'chat_effect_handler.dart';
import 'incoming_reaction_state_store.dart';
import 'message_edit_handler.dart';
import 'reaction_handler.dart';
import 'receipt_handler.dart';
import 'redaction_handler.dart';
import 'text_message_handler.dart';
import 'typing_handler.dart';

/// Routes incoming [MatrixRoomEvent]s for a [MatrixChatSDK].
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
  IncomingRoomEventRouter({required MatrixChatSDK chatSDK})
    : _matrixHandlers = buildBaseHandlers(chatSDK),
      _chatHandlers = const {},
      _chatStream = chatSDK.chatStream;

  @protected
  IncomingRoomEventRouter.withHandlers({
    required Map<String, MatrixRoomEventHandler> matrixHandlers,
    required Map<String, ChatEventHandler> chatHandlers,
    ChatStream? chatStream,
  }) : _matrixHandlers = matrixHandlers,
       _chatHandlers = chatHandlers,
       _chatStream = chatStream;

  /// Common matrix-coupled handler map shared by all chat types.
  @protected
  static Map<String, MatrixRoomEventHandler> buildBaseHandlers(
    MatrixChatSDK chatSDK,
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
        logger: chatSDK.logger,
        editHandler: MessageEditHandler(
          chatRepository: chatSDK.chatRepository,
          chatStream: chatSDK.chatStream,
          chatId: chatSDK.chatId,
          serverEventIdToMessageId: chatSDK.serverEventIdToMessageId,
          logger: chatSDK.logger,
        ),
      ).handle,
    };
  }

  final Map<String, MatrixRoomEventHandler> _matrixHandlers;
  final Map<String, ChatEventHandler> _chatHandlers;
  final ChatStream? _chatStream;

  Future<void> route(MatrixRoomEvent event) async {
    final dispatchKey = _translate(event);
    if (dispatchKey == null) return;

    final matrixHandler = _matrixHandlers[dispatchKey];
    if (matrixHandler != null) {
      return matrixHandler(event);
    }

    final chatHandler = _chatHandlers[dispatchKey];
    if (chatHandler != null) {
      return chatHandler.handle(
        IncomingChatEvent(
          type: dispatchKey,
          senderDid: event.senderDid,
          content: event.content,
        ),
      );
    }

    // No handler matched. Surface the raw event to SDK consumers as an
    // [UnhandledChatEvent] so they can act on protocol types the SDK does
    // not natively process.
    _chatStream?.pushData(
      StreamData(
        event: UnhandledChatEvent(
          type: event.type,
          senderDid: event.senderDid,
          body: event.content,
          createdTime: event.timestamp,
        ),
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
    if (event.type == MeetingPlaceProtocol.groupDeletion.value) {
      return ChatEventTypes.groupDeletion;
    }
    return switch (event.type) {
      'com.affinidi.chat.group-deletion' => ChatEventTypes.groupDeletion,
      'com.affinidi.chat.group-details-update' =>
        ChatEventTypes.groupDetailsUpdate,
      'com.affinidi.chat.contact-details-update' =>
        ChatEventTypes.contactDetailsUpdate,
      'com.affinidi.chat.effect' => ChatEventTypes.chatEffect,
      _ => event.type,
    };
  }
}
