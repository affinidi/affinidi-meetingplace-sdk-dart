import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:uuid/uuid.dart';

import '../../../entity/message_matrix_factory.dart';
import '../../../event/chat_event_conversion.dart';
import '../../../matrix_room_event.dart';
import '../matrix_media_attachment.dart';

/// Handles incoming `mpx.call.item` events by persisting the call item as a
/// message with a single metadata-only attachment and pushing it to the chat
/// stream.
class CallItemHandler {
  CallItemHandler({
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

  static const _logKey = 'CallItemHandler';

  final ChatRepository _chatRepository;
  final ChatStream _chatStream;
  final String _chatId;
  final Map<String, String> _serverEventIdToMessageId;
  final MeetingPlaceChatSDKLogger _logger;

  Future<void> handle(MatrixRoomEvent event) async {
    final senderDid = event.senderDid;
    if (senderDid == null) {
      _logger.warning(
        '''Could not resolve sender DID for call item event ${event.id}, skipping.''',
        name: _logKey,
      );
      return;
    }

    final rawMetadata = event.content[MatrixEventField.callMetadata];
    if (rawMetadata is! Map) {
      _logger.warning(
        'Call item event ${event.id} has no valid metadata, skipping.',
        name: _logKey,
      );
      return;
    }

    try {
      final attachment = ChatAttachment(
        id: const Uuid().v4(),
        metadata: Map<String, dynamic>.from(rawMetadata),
      );
      attachment.transportId = event.id;

      final message = event.toMessage(
        chatId: _chatId,
        senderDid: senderDid,
        attachments: [attachment],
        isFromMe: false,
        status: ChatItemStatus.received,
      );
      _serverEventIdToMessageId[event.id] = message.messageId;
      final chatItem = await _chatRepository.createMessage(message);
      _chatStream.pushData(
        StreamData(event: event.toChatEvent(), chatItem: chatItem),
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to create message from call item event',
        error: e,
        stackTrace: stackTrace,
        name: _logKey,
      );
    }
  }
}
