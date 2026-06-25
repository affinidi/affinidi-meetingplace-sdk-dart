import 'package:meeting_place_core/meeting_place_core.dart';

/// A [MatrixOutgoingMessage] that writes a `mpx.call.invite` timeline event
/// to the shared Matrix room.
///
/// The event carries the call's [CallMediaType] both in its timeline content
/// and on the accompanying `call-invite` control-plane nudge, so the
/// recipient's incoming-call UI can render the correct media type immediately
/// from the nudge without a follow-up fetch.
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
           mediaType: mediaType,
         ),
       );
}
