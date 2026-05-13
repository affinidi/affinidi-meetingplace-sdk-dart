import 'package:meeting_place_core/meeting_place_core.dart';

import '../protocol.dart';

/// A [DidCommOutgoingMessage] carrying a [ChatMessage] protocol payload —
/// the primary text-message envelope sent over DIDComm.
class ChatTextMessage extends DidCommOutgoingMessage {
  ChatTextMessage({
    required super.senderDid,
    required super.recipientDid,
    required super.mediatorDid,
    required ChatMessage chatMessage,
    super.notifyChannelType,
  }) : super(payload: chatMessage.toPlainTextMessage());
}
