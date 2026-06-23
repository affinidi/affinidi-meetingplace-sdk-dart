import 'package:meeting_place_core/meeting_place_core.dart';

import '../protocol.dart';

/// A [DidCommOutgoingMessage] carrying a [ChatEffect] protocol payload —
/// visual/animated chat effect sent over DIDComm.
class ChatEffectMessage extends DidCommOutgoingMessage {
  ChatEffectMessage({
    required super.senderDid,
    required super.recipientDid,
    required super.mediatorDid,
    required String effect,
  }) : super(
         payload: ChatEffect.create(
           from: senderDid,
           to: [recipientDid],
           effect: effect,
         ).toPlainTextMessage(),
       );
}
