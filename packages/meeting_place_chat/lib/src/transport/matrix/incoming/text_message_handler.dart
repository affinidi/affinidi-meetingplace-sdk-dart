import 'dart:async';

import 'package:meeting_place_core/meeting_place_core.dart';

import '../../../../meeting_place_chat.dart';
import '../../../event/chat_event_conversion.dart';
import '../matrix_user_id_cache.dart';
import 'room_event_handler.dart';

/// Handles incoming `m.room.message` events. Resolves the sender DID,
/// persists the message, pushes it to the chat stream and fires a delivered
/// receipt.
class TextMessageHandler implements RoomEventHandler {
  TextMessageHandler({
    required ChatRepository chatRepository,
    required ChatStream chatStream,
    required String chatId,
    required MatrixUserIdCache didCache,
    required MeetingPlaceChatSDKLogger logger,
    required Future<void> Function(String messageId) sendDeliveredReceipt,
  }) : _chatRepository = chatRepository,
       _chatStream = chatStream,
       _chatId = chatId,
       _didCache = didCache,
       _logger = logger,
       _sendDeliveredReceipt = sendDeliveredReceipt;

  static const String _logkey = 'TextMessageHandler';

  final ChatRepository _chatRepository;
  final ChatStream _chatStream;
  final String _chatId;
  final MatrixUserIdCache _didCache;
  final MeetingPlaceChatSDKLogger _logger;
  final Future<void> Function(String messageId) _sendDeliveredReceipt;

  @override
  Future<void> handle(MatrixRoomEvent event) async {
    final senderDid = _didCache.resolve(event.userId);
    if (senderDid == null) {
      _logger.warning(
        'Could not resolve sender DID for event ${event.id}, skipping event.',
        name: _logkey,
      );
      return;
    }

    try {
      final message = Message.fromRoomEventReceivedByMe(
        event: event,
        chatId: _chatId,
        senderDid: senderDid,
      );

      final chatItem = await _chatRepository.createMessage(message);

      _chatStream.pushData(
        StreamData(event: event.toChatEvent(), chatItem: chatItem),
      );
    } catch (e) {
      // TODO: fix duplicate handling causing this error
      _logger.error(
        'Failed to create message from room event: $e',
        name: _logkey,
      );
    }

    unawaited(_sendDeliveredReceipt(event.id));
  }
}
