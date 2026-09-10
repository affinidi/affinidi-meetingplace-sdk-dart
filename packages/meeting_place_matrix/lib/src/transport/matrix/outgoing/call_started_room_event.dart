import '../../../call/mpx_call_event_type.dart';
import '../../../matrix_outgoing_message.dart';
import '../matrix_media_attachment.dart';

/// A [MatrixOutgoingMessage] signalling that a call has connected.
///
/// Sends a `mpx.call.started` room event carrying the call ID and a
/// signature over it; the authoritative start time is the event's
/// homeserver `originServerTs`, never a value from the payload. The
/// signature lets a receiver verify the sender genuinely holds the DID it
/// claims, rather than trusting room membership alone.
class CallStartedRoomEvent extends MatrixOutgoingMessage {
  CallStartedRoomEvent({
    required super.senderDid,
    required String callId,
    required String signature,
  }) : super(
         type: MpxCallEventType.callStarted,
         content: {
           MatrixEventField.callId: callId,
           MatrixEventField.callSignature: signature,
         },
       );
}
