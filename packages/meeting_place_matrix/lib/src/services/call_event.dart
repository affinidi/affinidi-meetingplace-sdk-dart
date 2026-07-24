import '../../../meeting_place_matrix.dart';

/// Sealed set of events that drive the call state machine.
///
/// The service dispatches one event per external trigger or async completion.
/// The reducer maps (currentState, event) to a transition result without
/// touching timers or I/O.
sealed class CallEvent {}

/// The local device is joining — credentials resolved, room connected.
class CallJoinCompleted extends CallEvent {
  CallJoinCompleted({
    required this.ownRole,
    required this.callId,
    required this.isRejoin,
    required this.hasPeer,
  });

  final CallRole ownRole;
  final String callId;
  final bool isRejoin;
  final bool hasPeer;
}

/// The outgoing call invite was sent; the caller is now ringing.
class CallInviteSent extends CallEvent {
  CallInviteSent({required this.participants});

  final List<AudioVideoCallParticipant> participants;
}

/// A remote peer joined the room.
class CallPeerJoined extends CallEvent {
  CallPeerJoined({required this.participants, required this.callStartedAt});

  final List<AudioVideoCallParticipant> participants;
  final DateTime callStartedAt;
}

/// Participant list updated but no promotion-triggering change occurred.
class CallParticipantsUpdated extends CallEvent {
  CallParticipantsUpdated({required this.participants});

  final List<AudioVideoCallParticipant> participants;
}

/// A non-self peer's E2EE key is ready.
class CallPeerKeyed extends CallEvent {
  CallPeerKeyed({required this.participants});

  final List<AudioVideoCallParticipant> participants;
}

/// Peer declined the call before answering.
class CallDeclineReceived extends CallEvent {}

/// No answer within the outgoing call timeout window.
class CallOutgoingTimeoutFired extends CallEvent {}

/// E2EE key-ready timeout fired while waiting for keys.
class CallE2eeTimeoutFired extends CallEvent {
  CallE2eeTimeoutFired({required this.participants});

  final List<AudioVideoCallParticipant> participants;
}

/// The local device is leaving the call.
class CallLeaveRequested extends CallEvent {
  CallLeaveRequested({
    required this.hasPeer,
    required this.cancelledBeforeAnswer,
  });

  final bool hasPeer;
  final bool cancelledBeforeAnswer;
}

/// Join failed with an error.
class CallJoinFailed extends CallEvent {
  CallJoinFailed({required this.errorCode});

  final AudioVideoCallErrorCode errorCode;
}
