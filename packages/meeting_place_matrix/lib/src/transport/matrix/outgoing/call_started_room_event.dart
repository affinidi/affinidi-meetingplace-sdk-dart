import '../../../call/mpx_call_event_type.dart';
import '../../../matrix_outgoing_message.dart';
import '../matrix_media_attachment.dart';

/// A [MatrixOutgoingMessage] signalling that a call has connected.
///
/// Sends a `mpx.call.started` room event carrying only the call ID; the
/// authoritative start time is the event's homeserver `originServerTs`, never
/// a value from the payload.
class CallStartedRoomEvent extends MatrixOutgoingMessage {
  CallStartedRoomEvent({required super.senderDid, required String callId})
    : super(
        type: MpxCallEventType.callStarted,
        content: {MatrixEventField.callId: callId},
      );
}
