import 'package:meeting_place_core/meeting_place_core.dart';

import '../../../../meeting_place_chat.dart';
import '../../../event/chat_event_conversion.dart';
import 'message_edit_handler.dart';

/// Handles incoming `m.room.message` events. Persists the message and pushes
/// it to the chat stream. Sender DID is supplied by core's `MessagingService`
/// via [MatrixRoomEvent.senderDid].
///
/// `m.room.message` events that carry an `m.replace` relation are delegated
/// to [MessageEditHandler] which mutates the target message in place.
///
/// Delivery receipts are issued by the SDK after handling completes, so the
/// buffered-fetch path can send a single cumulative receipt for the latest
/// event rather than one per message (Matrix `m.read` is cumulative).
class TextMessageHandler {
  TextMessageHandler({
    required ChatRepository chatRepository,
    required ChatStream chatStream,
    required String chatId,
    required MeetingPlaceChatSDKLogger logger,
    required MessageEditHandler editHandler,
  }) : _chatRepository = chatRepository,
       _chatStream = chatStream,
       _chatId = chatId,
       _logger = logger,
       _editHandler = editHandler;

  static const String _logkey = 'TextMessageHandler';

  final ChatRepository _chatRepository;
  final ChatStream _chatStream;
  final String _chatId;
  final MeetingPlaceChatSDKLogger _logger;
  final MessageEditHandler _editHandler;

  Future<void> handle(MatrixRoomEvent event) async {
    final relatesTo = event.content['m.relates_to'] as Map<String, dynamic>?;
    if (relatesTo?['rel_type'] == 'm.replace') {
      return _editHandler.handle(event);
    }

    final senderDid = event.senderDid;
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
  }
}
