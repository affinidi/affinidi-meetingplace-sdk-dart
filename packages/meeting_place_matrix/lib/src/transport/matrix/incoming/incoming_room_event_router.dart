import 'package:matrix/matrix.dart' as matrix;
import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meta/meta.dart';

import '../../../call/mpx_call_event_type.dart';
import '../../../chat/meeting_place_matrix_chat_sdk.dart';
import '../../../matrix_room_event.dart';
import '../matrix_chat_event_type.dart';
import 'call_item_handler.dart';
import 'call_outcome_handler.dart';
import 'chat_effect_handler.dart';
import 'incoming_reaction_state_store.dart';
import 'message_edit_handler.dart';
import 'reaction_handler.dart';
import 'receipt_handler.dart';
import 'redaction_handler.dart';
import 'text_message_handler.dart';
import 'typing_handler.dart';

/// Routes incoming [MatrixRoomEvent]s for a [MeetingPlaceMatrixChatSDK].
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
  IncomingRoomEventRouter({required MeetingPlaceMatrixChatSDK chatSDK})
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
    MeetingPlaceMatrixChatSDK chatSDK,
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
      MpxCallEventType.callItem: CallItemHandler(
        chatRepository: chatSDK.chatRepository,
        chatStream: chatSDK.chatStream,
        chatId: chatSDK.chatId,
        serverEventIdToMessageId: chatSDK.serverEventIdToMessageId,
        logger: chatSDK.logger,
      ).handle,
      MpxCallEventType.callOutcome: CallOutcomeHandler(
        chatStream: chatSDK.chatStream,
        logger: chatSDK.logger,
      ).handle,
      matrix.EventTypes.Message: TextMessageHandler(
        chatRepository: chatSDK.chatRepository,
        chatStream: chatSDK.chatStream,
        chatId: chatSDK.chatId,
        serverEventIdToMessageId: chatSDK.serverEventIdToMessageId,
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

  // Tracks event IDs already dispatched to chat handlers. Prevents double-
  // dispatch when fetchRoomHistory's requestHistory() fires onTimelineEvent
  // for the same events that the bootstrap loop already processed.
  final _processedChatEventIds = <String>{};

  Future<void> route(MatrixRoomEvent event) async {
    final dispatchKey = _translate(event);
    if (dispatchKey == null) return;

    final matrixHandler = _matrixHandlers[dispatchKey];
    if (matrixHandler != null) {
      return matrixHandler(event);
    }

    final chatHandler = _chatHandlers[dispatchKey];
    if (chatHandler != null) {
      if (!_processedChatEventIds.add(event.id)) return;
      return chatHandler.handle(
        IncomingChatEvent(
          type: dispatchKey,
          senderDid: event.senderDid,
          targetDid: resolveTargetDid(event),
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
    return switch (event.type) {
      MatrixChatEventType.groupDeletion => ChatEventTypes.groupDeletion,
      MatrixChatEventType.groupDetailsUpdate =>
        ChatEventTypes.groupDetailsUpdate,
      MatrixChatEventType.contactDetailsUpdate =>
        ChatEventTypes.contactDetailsUpdate,
      MatrixChatEventType.chatEffect => ChatEventTypes.chatEffect,
      _ => event.type,
    };
  }

  /// Resolves the target DID for a given event, if applicable.
  /// Returns `null` by default. Subclasses can override to provide
  /// context-specific resolution (e.g., resolving the affected user in
  /// a membership change from the group's member list).
  @protected
  String? resolveTargetDid(MatrixRoomEvent event) => null;
}
