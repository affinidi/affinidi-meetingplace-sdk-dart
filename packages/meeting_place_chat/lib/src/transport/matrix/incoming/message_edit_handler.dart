import 'dart:async';

import 'package:meeting_place_core/meeting_place_core.dart';

import '../../../../meeting_place_chat.dart';
import '../../../event/chat_event_conversion.dart';

/// Handles incoming `m.room.message` events that carry an `m.replace`
/// relation (Matrix message edits). Mutates the target message's body and
/// `editedAt` in place rather than producing a new [Message].
class MessageEditHandler {
  MessageEditHandler({
    required ChatRepository chatRepository,
    required ChatStream chatStream,
    required String chatId,
    required Map<String, String> serverEventIdToMessageId,
    required MeetingPlaceChatSDKLogger logger,
  }) : _chatRepository = chatRepository,
       _chatStream = chatStream,
       _chatId = chatId,
       _serverEventIdToMessageId = serverEventIdToMessageId,
       _logger = logger;

  static const String _logkey = 'MessageEditHandler';

  final ChatRepository _chatRepository;
  final ChatStream _chatStream;
  final String _chatId;
  final Map<String, String> _serverEventIdToMessageId;
  final MeetingPlaceChatSDKLogger _logger;

  Future<void> handle(MatrixRoomEvent event) async {
    final relatesTo = event.content['m.relates_to'] as Map<String, dynamic>?;
    final targetEventId = relatesTo?['event_id'] as String?;
    final newContent = event.content['m.new_content'] as Map<String, dynamic>?;
    final newBody = newContent?['body'] as String?;
    if (targetEventId == null || newBody == null) return;

    final stored = await _resolveTargetMessage(targetEventId);
    if (stored == null) {
      _logger.info(
        'Edit for unknown message $targetEventId, dropping',
        name: _logkey,
      );
      return;
    }

    final senderDid = event.senderDid;
    if (senderDid == null || senderDid != stored.senderDid) {
      _logger.warning(
        'Edit from non-author for message ${stored.messageId}, dropping',
        name: _logkey,
      );
      return;
    }

    final lastEditedAt = stored.editedAt;
    if (lastEditedAt != null && !event.timestamp.isAfter(lastEditedAt)) {
      return;
    }

    stored.value = newBody;
    stored.editedAt = event.timestamp;
    await _chatRepository.updateMesssage(stored);
    _chatStream.pushData(
      StreamData(event: event.toChatEvent(), chatItem: stored),
    );
  }

  /// Resolves the local [Message] targeted by an edit's Matrix event id.
  ///
  /// The in-memory [_serverEventIdToMessageId] map only covers messages seen
  /// live this session, so it misses history and cross-session messages. Fall
  /// back to the persisted `transportId` (the Matrix event id) so edits on
  /// older messages still resolve instead of being dropped.
  Future<Message?> _resolveTargetMessage(String targetEventId) async {
    final mappedId = _serverEventIdToMessageId[targetEventId];
    if (mappedId != null) {
      final mapped = await _chatRepository.getMessage(
        chatId: _chatId,
        messageId: mappedId,
      );
      if (mapped is Message) return mapped;
    }

    final direct = await _chatRepository.getMessage(
      chatId: _chatId,
      messageId: targetEventId,
    );
    if (direct is Message) return direct;

    final items = await _chatRepository.listMessages(_chatId);
    for (final item in items) {
      if (item is Message && item.transportId == targetEventId) return item;
    }
    return null;
  }
}
