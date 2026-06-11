import 'package:meeting_place_core/meeting_place_core.dart';

import '../matrix_chat_event_type.dart';

class EffectRoomEvent extends MatrixOutgoingMessage {
  EffectRoomEvent({required super.senderDid, required String effect})
    : super(type: MatrixChatEventType.chatEffect, content: {'effect': effect});
}
