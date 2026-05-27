import 'package:meeting_place_core/meeting_place_core.dart';

class EffectRoomEvent extends MatrixOutgoingMessage {
  EffectRoomEvent({
    required super.senderDid,
    required super.roomId,
    required String effect,
  }) : super(
         type: 'com.affinidi.chat.effect',
         content: {'effect': effect},
       );
}
