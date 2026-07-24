import '../call/call_media_type.dart';

/// Tracks ringing calls and the busy-guard for
/// `MeetingPlaceLiveKitCallPlugin`.
///
/// Holds three pieces of state:
/// 1. Pending calls (ringing, not yet accepted): callId → otherPartyChannelDid.
/// 2. The active call id (busy guard — non-null while a call is ringing or
///    connected).
/// 3. The accepted-but-not-yet-started channel DID set when a ringing call is
///    accepted and consumed when the session role is resolved.
typedef PendingCallDetails = ({
  String otherPartyChannelDid,
  CallMediaType mediaType,
});

class PendingCallManager {
  PendingCallManager({
    Duration preemptiveDeclineWindow = const Duration(seconds: 2),
    DateTime Function() now = DateTime.now,
  }) : _preemptiveDeclineWindow = preemptiveDeclineWindow,
       _now = now;

  final Map<String, PendingCallDetails> _pendingCalls = {};
  final Set<String> _pendingIncomingReservations = {};
  final Map<String, DateTime> _preemptiveDeclines = {};
  final Duration _preemptiveDeclineWindow;
  final DateTime Function() _now;
  String? _activeCallId;
  bool _outboundActive = false;
  String? _acceptedOtherPartyChannelDid;
  String? _activePeerDid;

  /// True while a call is ringing or active on this device.
  bool get isBusy => _activeCallId != null || _outboundActive;

  /// True when this device is currently in a call with [otherPartyChannelDid].
  ///
  /// Used to recognise a re-invite from the party we are already talking to (a
  /// reconnect) so it is ignored rather than auto-declined as a competing call.
  bool isInCallWith(String otherPartyChannelDid) =>
      isBusy && _activePeerDid == otherPartyChannelDid;

  /// Returns true while an incoming call from [otherPartyChannelDid] is being
  /// resolved before it is fully registered.
  bool hasIncomingReservation(String otherPartyChannelDid) =>
      _pendingIncomingReservations.contains(otherPartyChannelDid);

  /// True while [callId] is registered as a ringing (not yet accepted) call.
  bool isRinging(String callId) => _pendingCalls.containsKey(callId);

  /// Registers [callId] as a new incoming ringing call.
  ///
  /// Returns false when [isBusy] — a call is already ringing or active.
  /// The caller is responsible for logging and silently dropping the event;
  /// no busy signal is sent back to the remote party.
  bool registerIncomingCall({
    required String callId,
    required String otherPartyChannelDid,
    required CallMediaType mediaType,
  }) {
    if (isBusy) return false;
    _activeCallId = callId;
    _activePeerDid = otherPartyChannelDid;
    _pendingCalls[callId] = (
      otherPartyChannelDid: otherPartyChannelDid,
      mediaType: mediaType,
    );
    return true;
  }

  /// Reserves an incoming call slot for [otherPartyChannelDid] before async
  /// identity resolution finishes.
  bool reserveIncomingCall(String otherPartyChannelDid) {
    if (isBusy) return false;
    _pendingIncomingReservations.add(otherPartyChannelDid);
    _activePeerDid = otherPartyChannelDid;
    return true;
  }

  /// Releases a previously reserved incoming call slot.
  void releaseIncomingReservation(String otherPartyChannelDid) {
    _pendingIncomingReservations.remove(otherPartyChannelDid);
    if (_pendingIncomingReservations.isEmpty && _pendingCalls.isEmpty) {
      _activePeerDid = null;
    }
  }

  /// Accepts [callId] and marks it as accepted-not-yet-started.
  ///
  /// Returns the otherPartyChannelDid, or null if [callId] is not pending.
  String? acceptCall(String callId) {
    final did = _pendingCalls.remove(callId)?.otherPartyChannelDid;
    if (did != null) _acceptedOtherPartyChannelDid = did;
    return did;
  }

  /// Removes [callId] from pending and clears the busy guard if it matches.
  ///
  /// Returns the otherPartyChannelDid so the caller can send a decline signal.
  String? declineCall(String callId) {
    final did = _pendingCalls.remove(callId)?.otherPartyChannelDid;
    if (_activeCallId == callId) {
      _activeCallId = null;
      _activePeerDid = null;
    }
    return did;
  }

  /// Clears a reserved incoming call for [otherPartyChannelDid], if present.
  void cancelReservedIncomingCall(String otherPartyChannelDid) {
    releaseIncomingReservation(otherPartyChannelDid);
  }

  /// Records a decline that arrived before its incoming call was registered.
  ///
  /// A pending-notification replay can deliver a caller's cancel ahead of the
  /// buffered invite. Recording it lets the invite that follows from the same
  /// peer be dropped via [consumePreemptiveDecline] instead of ringing anew.
  void recordPreemptiveDecline(String otherPartyChannelDid) {
    _preemptiveDeclines[otherPartyChannelDid] = _now();
  }

  /// Consumes a pre-emptive decline for [otherPartyChannelDid].
  ///
  /// Returns true when a decline was recorded within the decline window, in
  /// which case the incoming call should be dropped. The record is removed
  /// whether or not it was still within the window.
  bool consumePreemptiveDecline(String otherPartyChannelDid) {
    final declinedAt = _preemptiveDeclines.remove(otherPartyChannelDid);
    if (declinedAt == null) return false;
    return _now().difference(declinedAt) <= _preemptiveDeclineWindow;
  }

  /// Resolves whether [otherPartyChannelDid] is a recipient scenario and
  /// consumes the relevant state.
  ///
  /// Returns whether the local device should join as a recipient, and the
  /// pending callId that was removed from the registry (if any).
  ({bool isRecipient, String? pendingCallId}) resolveRole(
    String otherPartyChannelDid,
  ) {
    String? pendingCallId;
    for (final entry in _pendingCalls.entries) {
      if (entry.value.otherPartyChannelDid == otherPartyChannelDid) {
        pendingCallId = entry.key;
        break;
      }
    }
    final isRecipient =
        _acceptedOtherPartyChannelDid == otherPartyChannelDid ||
        pendingCallId != null;
    _acceptedOtherPartyChannelDid = null;
    if (pendingCallId != null) _pendingCalls.remove(pendingCallId);
    return (isRecipient: isRecipient, pendingCallId: pendingCallId);
  }

  /// Clears the busy guard without requiring a matching callId.
  ///
  /// Call this when a session that was accepted and joined ends normally
  /// (hangup from screen, call ended by peer, plugin disposed). Without this,
  /// [isBusy] stays true after [acceptCall] since that method only removes from
  /// [_pendingCalls] but does not clear [_activeCallId].
  void clearActiveCall() {
    _activeCallId = null;
    _outboundActive = false;
    _pendingIncomingReservations.clear();
    _activePeerDid = null;
  }

  /// Marks an outbound (caller-initiated) call to [otherPartyChannelDid] as
  /// active so the busy guard rejects concurrent incoming calls and recognises
  /// a re-invite from that same peer. No-op if already busy.
  void markOutboundCall(String otherPartyChannelDid) {
    if (!isBusy) {
      _outboundActive = true;
      _activePeerDid = otherPartyChannelDid;
    }
  }

  /// Removes the pending call for [otherPartyChannelDid], if any.
  ///
  /// Returns the callId that was removed, or null. Clears the busy guard when
  /// the removed call was the active call.
  ({String callId, CallMediaType mediaType})? removePendingByDid(
    String otherPartyChannelDid,
  ) {
    String? callId;
    for (final entry in _pendingCalls.entries) {
      if (entry.value.otherPartyChannelDid == otherPartyChannelDid) {
        callId = entry.key;
        break;
      }
    }
    if (callId == null) {
      return null;
    }

    final details = _pendingCalls.remove(callId)!;
    if (_activeCallId == callId) {
      _activeCallId = null;
      _activePeerDid = null;
    }
    return (callId: callId, mediaType: details.mediaType);
  }

  /// Returns the pending caller DID for [callId], or null when it is unknown.
  String? otherPartyChannelDidFor(String callId) =>
      _pendingCalls[callId]?.otherPartyChannelDid;
}
