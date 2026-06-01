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

    final messageId = _serverEventIdToMessageId[targetEventId] ?? targetEventId;
    final stored = await _chatRepository.getMessage(
      chatId: _chatId,
      messageId: messageId,
    );
    if (stored == null || stored is! Message) {
      _logger.info(
        'Edit for unknown message $targetEventId, dropping',
        name: _logkey,
      );
      return;
    }

    final senderDid = event.senderDid;
    if (senderDid == null || senderDid != stored.senderDid) {
      _logger.warning(
        'Edit from non-author for message $messageId, dropping',
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
}
