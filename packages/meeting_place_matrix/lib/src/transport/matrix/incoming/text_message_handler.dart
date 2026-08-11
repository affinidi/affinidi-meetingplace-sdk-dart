import 'package:meeting_place_chat/meeting_place_chat.dart';

import '../../../entity/message_matrix_factory.dart';
import '../../../event/chat_event_conversion.dart';
import '../../../matrix_room_event.dart';
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
    if (event.content.containsKey(MatrixEventField.memberDid)) return;

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
      final textBody = event.content['body'] as String? ?? '';
      final signRequest = CiergeSignDocumentRequest.fromMessageText(textBody);

      _logger.info(
        'Incoming text event '
        'eventId=${event.id} '
        'correlationId=${correlationId ?? '-'} '
        'senderDid=$senderDid '
        'attachmentCount=${attachments.length} '
        'isSignRequest=${signRequest != null}',
        name: _logkey,
      );

      final logicalMessageId = correlationId ?? event.id;
      final existing = await _chatRepository.getMessage(
        chatId: _chatId,
        messageId: logicalMessageId,
      );

      if (signRequest != null) {
        _logger.info(
          'Routing sign request as ConciergeMessage '
          'eventId=${event.id} logicalMessageId=$logicalMessageId '
          'attachmentCount=${attachments.length}',
          name: _logkey,
        );
        final concierge = ConciergeMessage(
          chatId: _chatId,
          messageId: logicalMessageId,
          senderDid: senderDid,
          isFromMe: false,
          dateCreated: event.timestamp,
          status: ChatItemStatus.userInput,
          conciergeType: ConciergeMessageType.fromJson(
            CiergeSignDocumentRequest.conciergeTypeName,
          ),
          data: {
            'document': signRequest.document,
            'taskId': signRequest.taskId,
          },
          attachments: _mergeAttachments(
            existing is ConciergeMessage ? existing.attachments : null,
            attachments,
          ),
        );

        if (correlationId != null) {
          _serverEventIdToMessageId[event.id] = correlationId;
        }

        final chatItem = switch (existing) {
          ConciergeMessage _ => await _chatRepository.updateMesssage(concierge),
          Message message => await _chatRepository.updateMesssage(
            ConciergeMessage(
              chatId: message.chatId,
              messageId: logicalMessageId,
              senderDid: senderDid,
              isFromMe: false,
              dateCreated: message.dateCreated,
              status: message.status,
              conciergeType: ConciergeMessageType.fromJson(
                CiergeSignDocumentRequest.conciergeTypeName,
              ),
              data: {
                'document': signRequest.document,
                'taskId': signRequest.taskId,
              },
              attachments: _mergeAttachments(message.attachments, attachments),
            ),
          ),
          _ => await _chatRepository.createMessage(concierge),
        };
        _chatStream.pushData(
          StreamData(event: event.toChatEvent(), chatItem: chatItem),
        );
        return;
      }

      // Legacy / non-correlated event: one event → one Message, keyed on the
      // matrix event id.
      if (correlationId == null) {
        final stepUpRequest = CiergeStepUpApproveRequest.fromMessageText(
          textBody,
        );
        if (stepUpRequest != null) {
          final concierge = ConciergeMessage(
            chatId: _chatId,
            messageId: event.id,
            senderDid: senderDid,
            isFromMe: false,
            dateCreated: event.timestamp,
            status: ChatItemStatus.userInput,
            conciergeType: ConciergeMessageType.fromJson(
              CiergeStepUpApproveRequest.conciergeTypeName,
            ),
            data: {'approveRequest': stepUpRequest.approveRequest},
          );
          final chatItem = await _chatRepository.createMessage(concierge);
          _chatStream.pushData(
            StreamData(event: event.toChatEvent(), chatItem: chatItem),
          );
          return;
        }

        final message = event.toMessage(
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
      // Map each matrix event id back to the logical Message id so peer
      // edits/reactions/redactions targeting any one of the file events
      // resolve to this coalesced Message.
      _serverEventIdToMessageId[event.id] = correlationId;

      if (existing is ConciergeMessage) {
        _logger.info(
          'Coalescing correlated text event into existing ConciergeMessage '
          'eventId=${event.id} correlationId=$correlationId '
          'existingAttachmentCount=${existing.attachments?.length ?? 0} '
          'newAttachmentCount=${attachments.length}',
          name: _logkey,
        );
        final updated = ConciergeMessage(
          chatId: existing.chatId,
          messageId: existing.messageId,
          senderDid: existing.senderDid,
          isFromMe: existing.isFromMe,
          dateCreated: existing.dateCreated,
          status: existing.status,
          data: existing.data,
          conciergeType: existing.conciergeType,
          attachments: _mergeAttachments(existing.attachments, attachments),
        );
        final chatItem = await _chatRepository.updateMesssage(updated);
        _chatStream.pushData(
          StreamData(event: event.toChatEvent(), chatItem: chatItem),
        );
        return;
      }

      if (existing is Message) {
        _logger.info(
          'Coalescing correlated text event into existing Message '
          'eventId=${event.id} correlationId=$correlationId '
          'existingAttachmentCount=${existing.attachments.length} '
          'newAttachmentCount=${attachments.length}',
          name: _logkey,
        );
        final existingAttachmentIds = existing.attachments
            .map((attachment) => attachment.id)
            .toSet();
        final attachmentsToAdd = <ChatAttachment>[];
        for (final attachment in attachments) {
          if (existingAttachmentIds.add(attachment.id)) {
            attachmentsToAdd.add(attachment);
          }
        }
        final caption = MatrixMediaAttachments.extractCaption(event.content);
        if ((existing.value.isEmpty || existing.mentions.isEmpty) &&
            caption != null &&
            caption.isNotEmpty) {
          final updated = event.toMessage(
            chatId: _chatId,
            senderDid: senderDid,
            isFromMe: false,
            status: ChatItemStatus.received,
          );
          if (existing.value.isEmpty) {
            existing.value = updated.value;
          }
          if (existing.mentions.isEmpty) {
            existing.mentions = updated.mentions;
          }
        }
        existing.attachments = [...existing.attachments, ...attachmentsToAdd];
        await _chatRepository.updateMesssage(existing);
        _chatStream.pushData(
          StreamData(event: event.toChatEvent(), chatItem: existing),
        );
        return;
      }

      final message = event.toMessage(
        chatId: _chatId,
        senderDid: senderDid,
        attachments: attachments,
        messageId: correlationId,
        isFromMe: false,
        status: ChatItemStatus.received,
      );
      _logger.info(
        'Creating correlated Message '
        'eventId=${event.id} correlationId=$correlationId '
        'attachmentCount=${attachments.length}',
        name: _logkey,
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

  List<ChatAttachment>? _mergeAttachments(
    List<ChatAttachment>? existing,
    List<ChatAttachment> incoming,
  ) {
    if ((existing == null || existing.isEmpty) && incoming.isEmpty) {
      return null;
    }

    final merged = <ChatAttachment>[...?existing];
    final seenIds = merged.map((attachment) => attachment.id).toSet();
    for (final attachment in incoming) {
      if (seenIds.add(attachment.id)) {
        merged.add(attachment);
      }
    }
    return merged;
  }
}
