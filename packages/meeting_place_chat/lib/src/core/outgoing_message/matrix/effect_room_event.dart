import 'package:meeting_place_core/meeting_place_core.dart';

import '../../../protocol/chat_protocol.dart';

class EffectRoomEvent extends MatrixOutgoingMessage {
  EffectRoomEvent({
    required super.senderDid,
    required super.roomId,
    required String effect,
  }) : super(
         type: ChatProtocol.chatEffect.value,
         content: {'effect': effect},
       );
}
