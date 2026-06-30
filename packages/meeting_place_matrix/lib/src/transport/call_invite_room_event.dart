import 'package:meeting_place_core/meeting_place_core.dart';

import '../../meeting_place_matrix.dart';

/// A [MatrixOutgoingMessage] that writes a `mpx.call.invite` timeline event
/// to the shared Matrix room.
///
/// The event carries the call's [CallMediaType] in its timeline content.
/// The accompanying control-plane nudge uses a type-specific value
/// (`call-invite` or `call-invite-audio`) so the recipient's incoming-call UI
/// can render the correct media type immediately without a follow-up fetch.
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
           type: mediaType == CallMediaType.audio
               ? CallChannelActivityType.callInviteAudio
               : CallChannelActivityType.callInviteVideo,
         ),
       );
}
