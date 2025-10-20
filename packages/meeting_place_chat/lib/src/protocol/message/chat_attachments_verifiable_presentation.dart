import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

import '../chat_protocol.dart';

class ChatAttachmentsVerifiablePresentation extends PlainTextMessage {
  ChatAttachmentsVerifiablePresentation({
    required super.id,
    required super.from,
    required super.to,
  }) : super(
          type: Uri.parse(
            ChatProtocol.chatAttachmentsVerifiablePresentation.value,
          ),
          body: {'text': ''},
        );

  factory ChatAttachmentsVerifiablePresentation.create({
    required String from,
    required List<String> to,
    required int forwardExpiryInSeconds,
  }) {
    return ChatAttachmentsVerifiablePresentation(
      id: const Uuid().v4(),
      from: from,
      to: to,
    );
  }
}
