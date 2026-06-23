import 'package:meeting_place_core/meeting_place_core.dart';

/// A [MatrixOutgoingMessage] that writes a `mpx.call.invite` timeline event
/// to the shared Matrix room.
///
/// The event carries the call's [CallMediaType] so the recipient's
/// `ChannelActivityEventHandler` can read it when processing the
/// `call-invite` control-plane nudge.
class CallInviteRoomEvent extends MatrixOutgoingMessage {
  CallInviteRoomEvent({
    required super.senderDid,
    required CallMediaType mediaType,
    required String recipientDid,
  }) : super(
         type: MpxCallEventType.callInvite,
         content: {'mediaType': mediaType.name},
         notification: IndividualChannelNotification(
           recipientDid: recipientDid,
           type: ChannelActivityType.callInvite,
         ),
       );
}
