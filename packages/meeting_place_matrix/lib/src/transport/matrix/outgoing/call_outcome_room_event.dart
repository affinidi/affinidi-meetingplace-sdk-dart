import '../../../call/mpx_call_event_type.dart';
import '../../../matrix_outgoing_message.dart';
import '../matrix_media_attachment.dart';

/// A [MatrixOutgoingMessage] carrying the canonical `CallOutcomeRecord`.
///
/// Sends a `mpx.call.outcome` room event with the record embedded under
/// `mp_call_outcome`. The event carries no visible chat body; peers reconcile
/// the call chat item by `callId` and read the authoritative end time from the
/// event's homeserver `originServerTs`.
class CallOutcomeRoomEvent extends MatrixOutgoingMessage {
  CallOutcomeRoomEvent({
    required super.senderDid,
    required Map<String, dynamic> outcome,
    super.notification,
  }) : super(
         type: MpxCallEventType.callOutcome,
         content: {MatrixEventField.callOutcome: outcome},
       );
}
