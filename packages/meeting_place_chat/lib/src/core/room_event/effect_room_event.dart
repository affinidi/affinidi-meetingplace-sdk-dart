import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:uuid/uuid.dart';

import '../../protocol/chat_protocol.dart';

class EffectRoomEvent extends MatrixRoomEvent {
  EffectRoomEvent({
    required super.senderDid,
    required super.roomId,
    required String effect,
  }) : super(
         id: const Uuid().v4(),
         type: ChatProtocol.chatEffect.value,
         content: {'effect': effect},
         timestamp: DateTime.now().toUtc(),
       );
}
