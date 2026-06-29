import 'package:meeting_place_matrix/meeting_place_matrix.dart';

import 'package:meeting_place_chat/meeting_place_chat.dart';
import '../../../entity/message_matrix_factory.dart';
import '../../../event/chat_event_conversion.dart';
import '../matrix_media_attachment.dart';
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
    required Map<String, String> serverEventIdToMessageId,
    required MeetingPlaceChatSDKLogger logger,
    required MessageEditHandler editHandler,
  }) : _chatRepository = chatRepository,
       _chatStream = chatStream,
       _chatId = chatId,
       _serverEventIdToMessageId = serverEventIdToMessageId,
       _logger = logger,
       _editHandler = editHandler;

  static const String _logkey = 'TextMessageHandler';

  final ChatRepository _chatRepository;
  final ChatStream _chatStream;
  final String _chatId;
  final Map<String, String> _serverEventIdToMessageId;
  final MeetingPlaceChatSDKLogger _logger;
  final MessageEditHandler _editHandler;

  Future<void> handle(MatrixRoomEvent event) async {
    if (event.content.containsKey('mp_member_did')) return;

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
      final attachments = MatrixMediaAttachments.extractFromContent(
        event.content,
      );
      // Stamp the matrix event id on each extracted attachment so the
      // receiver can download bytes per-attachment without consulting the
      // parent Message.
      for (final a in attachments) {
        a.transportId = event.id;
      }

      final correlationId =
          event.content[MatrixEventField.correlationId] as String?;

      // Legacy / non-correlated event: one event → one Message, keyed on the
      // matrix event id.
      if (correlationId == null) {
        final message = messageFromRoomEvent(
          event: event,
          chatId: _chatId,
          senderDid: senderDid,
          attachments: attachments,
          isFromMe: false,
          status: ChatItemStatus.received,
        );
        final chatItem = await _chatRepository.createMessage(message);
        _chatStream.pushData(
          StreamData(event: event.toChatEvent(), chatItem: chatItem),
        );
        return;
      }

      // Correlated event: coalesce into a single logical Message keyed on
      // the sender-allocated correlation id. The first event of the group to
      // arrive (which may not be the first event sent — events can be
      // reordered by the homeserver) creates the Message; later events
      // append their attachments.
      final existing = await _chatRepository.getMessage(
        chatId: _chatId,
        messageId: correlationId,
      );

      // Map each matrix event id back to the logical Message id so peer
      // edits/reactions/redactions targeting any one of the file events
      // resolve to this coalesced Message.
      _serverEventIdToMessageId[event.id] = correlationId;

      if (existing is Message) {
        existing.attachments = [...existing.attachments, ...attachments];
        await _chatRepository.updateMesssage(existing);
        _chatStream.pushData(
          StreamData(event: event.toChatEvent(), chatItem: existing),
        );
        return;
      }

      final message = messageFromRoomEvent(
        event: event,
        chatId: _chatId,
        senderDid: senderDid,
        attachments: attachments,
        messageId: correlationId,
        isFromMe: false,
        status: ChatItemStatus.received,
      );
      final chatItem = await _chatRepository.createMessage(message);
      _chatStream.pushData(
        StreamData(event: event.toChatEvent(), chatItem: chatItem),
      );
    } catch (e, stackTrace) {
      // TODO: fix duplicate handling causing this error
      _logger.error(
        'Failed to create message from room event',
        error: e,
        stackTrace: stackTrace,
        name: _logkey,
      );
    }
  }
}
