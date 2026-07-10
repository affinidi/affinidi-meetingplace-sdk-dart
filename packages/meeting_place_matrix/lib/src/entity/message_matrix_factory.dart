import 'package:meeting_place_chat/meeting_place_chat.dart';

import '../matrix_room_event.dart';
import '../transport/matrix/matrix_media_attachment.dart';

extension MatrixRoomEventToMessage on MatrixRoomEvent {
  Message toMessage({
    required String chatId,
    required String senderDid,
    required bool isFromMe,
    required ChatItemStatus status,
    List<ChatAttachment> attachments = const [],
    String? messageId,
  }) {
    return Message(
      chatId: chatId,
      messageId: messageId ?? id,
      senderDid: senderDid,
      value: _valueFromContent(content),
      isFromMe: isFromMe,
      dateCreated: timestamp,
      status: status,
      attachments: attachments,
      transportId: id,
    );
  }

  String _valueFromContent(Map<String, dynamic> content) {
    final caption = MatrixMediaAttachments.extractCaption(content);
    if (caption != null) return caption;
    final value = content['body'];
    return value is String ? value : '';
  }
}
