import '../../meeting_place_matrix.dart';

/// Single source of truth for all call state machine rules and transitions.
///
/// Documents every valid state, transition, event, and guard. Consumers must
/// import and use these guards, never re-derive state logic inline.

/// Returns true if caller can still send cancel (not yet answered).
///
/// Valid in: `connecting`, `outgoingRinging`.
bool canCancelBeforeAnswer(AudioVideoCallStatus status) =>
    status == AudioVideoCallStatus.connecting ||
    status == AudioVideoCallStatus.outgoingRinging;

/// Returns true if peer joining should promote to `connected`.
///
/// Valid in: `outgoingRinging`, `waitingForKeys`.
bool canConnectOnPeerJoin(AudioVideoCallStatus status) =>
    status == AudioVideoCallStatus.outgoingRinging ||
    status == AudioVideoCallStatus.waitingForKeys;

/// Returns true if non-self peer E2EE ready can promote to `active`.
///
/// Valid in: `outgoingRinging`, `waitingForKeys`, `connected`.
bool canTransitionToActive(AudioVideoCallStatus status) =>
    status == AudioVideoCallStatus.outgoingRinging ||
    status == AudioVideoCallStatus.waitingForKeys ||
    status == AudioVideoCallStatus.connected;
