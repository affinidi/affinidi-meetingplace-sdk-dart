import '../../../meeting_place_matrix.dart';
import 'call_command.dart';
import 'call_event.dart';

/// The output of applying one [CallEvent] to the current [AudioVideoCallState].
class CallTransitionResult {
  const CallTransitionResult({
    required this.state,
    this.commands = const [],
    this.accepted = true,
  });

  /// Convenience constructor for events that do not cause a valid transition.
  const CallTransitionResult.ignored(AudioVideoCallState current)
    : state = current,
      commands = const [],
      accepted = false;

  /// The next state after applying the event.
  final AudioVideoCallState state;

  /// Side-effect intents to execute after [state] is applied.
  final List<CallCommand> commands;

  /// Whether the event was a valid transition from the current state.
  ///
  /// `false` means the current state was not changed and no commands should
  /// be executed. The service may choose to log an unexpected event.
  final bool accepted;
}

/// Pure transition function for the call state machine.
///
/// Maps the current [AudioVideoCallState] and a [CallEvent] to a
/// [CallTransitionResult]. Has no side effects: it never touches timers,
/// network, or streams. The service executes the returned commands after
/// applying the new state.
CallTransitionResult callTransition(
  AudioVideoCallState current,
  CallEvent event,
) {
  return switch (event) {
    CallJoinCompleted(:final ownRole, :final callId, :final hasPeer) =>
      _onJoinCompleted(
        current,
        ownRole: ownRole,
        callId: callId,
        hasPeer: hasPeer,
      ),

    CallInviteSent(:final participants) => CallTransitionResult(
      state: current.copyWith(
        status: AudioVideoCallStatus.outgoingRinging,
        participants: participants,
      ),
      commands: [StartOutgoingTimeout()],
    ),

    CallPeerJoined(:final participants, :final callStartedAt) => _onPeerJoined(
      current,
      participants: participants,
      callStartedAt: callStartedAt,
    ),

    CallParticipantsUpdated(:final participants) => CallTransitionResult(
      state: current.copyWith(participants: participants),
    ),

    CallPeerKeyed(:final participants) => _onPeerKeyed(
      current,
      participants: participants,
    ),

    CallDeclineReceived() => _onDeclineReceived(current),

    CallOutgoingTimeoutFired() => _onOutgoingTimeout(current),

    CallE2eeTimeoutFired(:final participants) => _onE2eeTimeout(
      current,
      participants: participants,
    ),

    CallLeaveRequested(:final hasPeer, :final cancelledBeforeAnswer) =>
      _onLeaveRequested(
        current,
        hasPeer: hasPeer,
        cancelledBeforeAnswer: cancelledBeforeAnswer,
      ),

    CallJoinFailed(:final errorCode) => CallTransitionResult(
      state: current.copyWith(
        status: AudioVideoCallStatus.error,
        errorCode: errorCode,
      ),
    ),
  };
}

// ---------------------------------------------------------------------------
// Private transition helpers
// ---------------------------------------------------------------------------

/// Handles join completion, branching on caller vs recipient role.
CallTransitionResult _onJoinCompleted(
  AudioVideoCallState current, {
  required CallRole ownRole,
  required String callId,
  required bool hasPeer,
}) {
  final nextState = current.copyWith(ownRole: ownRole, callId: callId);

  if (ownRole == CallRole.recipient) {
    if (hasPeer) {
      return CallTransitionResult(
        state: nextState.copyWith(
          status: AudioVideoCallStatus.connected,
          callStartedAt: DateTime.now(),
        ),
        commands: [StartE2eeTimeout()],
      );
    }
    return CallTransitionResult(
      state: nextState.copyWith(status: AudioVideoCallStatus.waitingForKeys),
      commands: [StartE2eeTimeout()],
    );
  }

  // Caller rejoin: treat as recipient path so media flows without re-invite.
  return CallTransitionResult(state: nextState);
}

/// Promotes to connected when the first remote peer joins the room.
CallTransitionResult _onPeerJoined(
  AudioVideoCallState current, {
  required List<AudioVideoCallParticipant> participants,
  required DateTime callStartedAt,
}) {
  final validStatuses = {
    AudioVideoCallStatus.outgoingRinging,
    AudioVideoCallStatus.waitingForKeys,
  };
  if (!validStatuses.contains(current.status)) {
    return CallTransitionResult(
      state: current.copyWith(participants: participants),
    );
  }
  return CallTransitionResult(
    state: current.copyWith(
      status: AudioVideoCallStatus.connected,
      participants: participants,
      callStartedAt: callStartedAt,
    ),
    commands: [CancelOutgoingTimeout(), StartE2eeTimeout()],
  );
}

/// Promotes to active once a peer's E2EE key is ready.
CallTransitionResult _onPeerKeyed(
  AudioVideoCallState current, {
  required List<AudioVideoCallParticipant> participants,
}) {
  final validStatuses = {
    AudioVideoCallStatus.outgoingRinging,
    AudioVideoCallStatus.waitingForKeys,
    AudioVideoCallStatus.connected,
  };
  if (!validStatuses.contains(current.status)) {
    return CallTransitionResult.ignored(current);
  }
  return CallTransitionResult(
    state: current.copyWith(
      status: AudioVideoCallStatus.active,
      participants: participants,
    ),
    commands: [CancelOutgoingTimeout(), CancelE2eeTimeout()],
  );
}

/// Handles a recipient decline signal before the call is answered.
CallTransitionResult _onDeclineReceived(AudioVideoCallState current) {
  final validStatuses = {
    AudioVideoCallStatus.connecting,
    AudioVideoCallStatus.outgoingRinging,
  };
  if (!validStatuses.contains(current.status)) {
    return CallTransitionResult.ignored(current);
  }
  return CallTransitionResult(
    state: current.copyWith(
      status: AudioVideoCallStatus.declined,
      participants: const [],
    ),
    commands: [CancelOutgoingTimeout(), LeaveMatrixCall(), DisconnectRoom()],
  );
}

/// Handles no-answer timeout while the caller is ringing.
CallTransitionResult _onOutgoingTimeout(AudioVideoCallState current) {
  if (current.status != AudioVideoCallStatus.outgoingRinging) {
    return CallTransitionResult.ignored(current);
  }
  return CallTransitionResult(
    state: current.copyWith(
      status: AudioVideoCallStatus.missed,
      participants: const [],
    ),
    commands: [LeaveMatrixCall(), DisconnectRoom(), SendCallCancel()],
  );
}

/// Falls back to connected when E2EE keys are not ready in time.
CallTransitionResult _onE2eeTimeout(
  AudioVideoCallState current, {
  required List<AudioVideoCallParticipant> participants,
}) {
  if (current.status != AudioVideoCallStatus.waitingForKeys) {
    return CallTransitionResult.ignored(current);
  }
  return CallTransitionResult(
    state: current.copyWith(
      status: AudioVideoCallStatus.connected,
      participants: participants,
    ),
  );
}

/// Handles local leave, emitting cancel or outcome commands as needed.
CallTransitionResult _onLeaveRequested(
  AudioVideoCallState current, {
  required bool hasPeer,
  required bool cancelledBeforeAnswer,
}) {
  final commands = <CallCommand>[
    CancelOutgoingTimeout(),
    CancelE2eeTimeout(),
    LeaveMatrixCall(),
    DisconnectRoom(),
  ];

  if (cancelledBeforeAnswer) {
    commands.add(SendCallCancel());
  } else if (!hasPeer) {
    final callId = current.callId;
    final startedAt = current.callStartedAt;
    if (callId != null && startedAt != null) {
      commands.add(SendCallOutcome(callId: callId, startedAt: startedAt));
    }
  }

  return CallTransitionResult(
    state: current.copyWith(
      status: AudioVideoCallStatus.disconnecting,
      participants: const [],
    ),
    commands: commands,
  );
}
