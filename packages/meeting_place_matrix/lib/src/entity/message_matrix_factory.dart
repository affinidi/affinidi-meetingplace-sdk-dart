import 'package:meeting_place_chat/meeting_place_chat.dart';

import '../matrix_room_event.dart';
import '../transport/matrix/matrix_media_attachment.dart';

Message messageFromRoomEvent({
  required MatrixRoomEvent event,
  required String chatId,
  required String senderDid,
  required bool isFromMe,
  required ChatItemStatus status,
  List<ChatAttachment> attachments = const [],
  String? messageId,
}) {
  return Message(
    chatId: chatId,
    messageId: messageId ?? event.id,
    senderDid: senderDid,
    value: _valueFromRoomEvent(event),
    isFromMe: isFromMe,
    dateCreated: event.timestamp,
    status: status,
    attachments: attachments,
    transportId: event.id,
  );
}

String _valueFromRoomEvent(MatrixRoomEvent event) {
  final caption = MatrixMediaAttachments.extractCaption(event.content);
  if (caption != null) return caption;
  final value = event.content['body'];
  return value is String ? value : '';
}
