import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:uuid/uuid.dart';

import '../../../../meeting_place_chat.dart';
import '../../../entity/chat_attachment_bytes.dart';
import '../matrix_media_attachment.dart';

/// Sends `text` + N media `attachments` as a single logical [Message].
///
/// Matrix's `m.image`/`m.file` events are single-file, so the wire still emits
/// N events; the receiver coalesces them back into one [Message] via
/// [MatrixEventField.correlationId]. The sender persists exactly one [Message]
/// (status `queued` → `sent`/`error`) and pushes two stream updates.
class MediaTextMessageSender {
  MediaTextMessageSender({
    required MeetingPlaceCoreSDK coreSDK,
    required String did,
    required String chatId,
    required ChatRepository chatRepository,
    required ChatStream chatStream,
    required Map<String, String> serverEventIdToMessageId,
    required Future<Channel> Function() getChannel,
    required MeetingPlaceChatSDKLogger logger,
  }) : _coreSDK = coreSDK,
       _did = did,
       _chatId = chatId,
       _chatRepository = chatRepository,
       _chatStream = chatStream,
       _serverEventIdToMessageId = serverEventIdToMessageId,
       _getChannel = getChannel,
       _logger = logger;

  static const String _logkey = 'MediaTextMessageSender';

  final MeetingPlaceCoreSDK _coreSDK;
  final String _did;
  final String _chatId;
  final ChatRepository _chatRepository;
  final ChatStream _chatStream;
  final Map<String, String> _serverEventIdToMessageId;
  final Future<Channel> Function() _getChannel;
  final MeetingPlaceChatSDKLogger _logger;

  Future<Message> send({
    required String text,
    required List<ChatAttachment> attachments,
  }) async {
    // Decode bytes up-front so a malformed attachment fails before any
    // partial wire traffic is sent.
    final attachmentBytes = [
      for (final a in attachments) a.decodeInlineBytes(),
    ];
    final contentTypes = [
      for (final a in attachments) _contentTypeForAttachment(a),
    ];

    final channel = await _getChannel();
    channel.increaseSeqNo();

    // Single logical id, used both as the persisted Message.messageId and as
    // the correlation field on every outgoing matrix file event.
    final messageId = const Uuid().v4();
    final timestamp = DateTime.now().toUtc();

    final displayAttachments = [
      for (var i = 0; i < attachments.length; i++)
        ChatAttachment(
          id: attachments[i].id,
          description: attachments[i].description,
          filename: attachments[i].filename,
          mediaType: attachments[i].mediaType,
          format: attachments[i].format,
          lastModifiedTime: attachments[i].lastModifiedTime,
          byteCount: attachments[i].byteCount ?? attachmentBytes[i].length,
          metadata: attachments[i].metadata,
        ),
    ];

    final message = Message(
      chatId: _chatId,
      messageId: messageId,
      senderDid: _did,
      value: text,
      isFromMe: true,
      dateCreated: timestamp,
      status: ChatItemStatus.queued,
      attachments: displayAttachments,
    );
    await _chatRepository.createMessage(message);
    _chatStream.pushData(StreamData(chatItem: message));

    try {
      for (var i = 0; i < attachments.length; i++) {
        final attachment = attachments[i];
        final caption = i == 0 && text.isNotEmpty ? text : null;
        final eventId = await _coreSDK.sendMediaMessage(
          channel,
          attachmentBytes[i],
          contentType: contentTypes[i],
          filename: attachment.filename,
          caption: caption,
          extraContent: _extraContentForAttachment(
            attachment,
            contentType: contentTypes[i],
            sizeBytes: attachmentBytes[i].length,
            correlationId: messageId,
          ),
        );
        if (eventId != null) {
          message.attachments[i].transportId = eventId;
          if (i == 0) {
            message.transportId = eventId;
            _serverEventIdToMessageId[eventId] = messageId;
          }
        }
      }

      message.status = ChatItemStatus.sent;
      await _chatRepository.updateMesssage(message);
      await _coreSDK.updateChannel(channel);
      _chatStream.pushData(StreamData(chatItem: message));

      _logger.info(
        'Media message sent with ${attachments.length} attachment(s)',
        name: _logkey,
      );
    } catch (e, stackTrace) {
      message.status = ChatItemStatus.error;
      await _chatRepository.updateMesssage(message);
      _chatStream.pushData(StreamData(chatItem: message));
      _logger.error(
        'Failed to send media message',
        error: e,
        stackTrace: stackTrace,
        name: _logkey,
      );
    }

    return message;
  }

  static String _contentTypeForAttachment(ChatAttachment attachment) {
    final mediaType = attachment.mediaType;
    if (!VoiceMessageMetadata.isVoice(attachment)) {
      return mediaType ?? 'application/octet-stream';
    }
    if (mediaType == null || mediaType.isEmpty) {
      return VoiceMessageMetadata.defaultMediaType;
    }
    if (!mediaType.toLowerCase().startsWith('audio/')) {
      throw ArgumentError.value(mediaType, 'mediaType', 'must be audio/*');
    }
    return mediaType;
  }

  static Map<String, dynamic> _extraContentForAttachment(
    ChatAttachment attachment, {
    required String contentType,
    required int sizeBytes,
    required String correlationId,
  }) {
    return {
      MatrixEventField.correlationId: correlationId,
      MatrixEventField.attachmentFormat: attachment.format,
      ...MatrixMediaAttachments.buildVoiceContent(
        attachment,
        contentType: contentType,
        sizeBytes: sizeBytes,
      ),
    };
  }
}
