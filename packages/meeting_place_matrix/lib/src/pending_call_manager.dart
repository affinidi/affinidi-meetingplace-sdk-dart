/// Tracks ringing calls and the busy-guard for
/// `MeetingPlaceLiveKitCallPlugin`.
///
/// Holds three pieces of state:
/// 1. Pending calls (ringing, not yet accepted): callId → otherPartyChannelDid.
/// 2. The active call id (busy guard — non-null while a call is ringing or
///    connected).
/// 3. The accepted-but-not-yet-started channel DID (set by [acceptCall],
///    consumed by [resolveRole]).
class PendingCallManager {
  final Map<String, String> _pendingCalls = {};
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
  }) {
    if (isBusy) return false;
    _activeCallId = callId;
    _activePeerDid = otherPartyChannelDid;
    _pendingCalls[callId] = otherPartyChannelDid;
    return true;
  }

  /// Accepts [callId] and marks it as accepted-not-yet-started.
  ///
  /// Returns the otherPartyChannelDid, or null if [callId] is not pending.
  String? acceptCall(String callId) {
    final did = _pendingCalls.remove(callId);
    if (did != null) _acceptedOtherPartyChannelDid = did;
    return did;
  }

  /// Removes [callId] from pending and clears the busy guard if it matches.
  ///
  /// Returns the otherPartyChannelDid so the caller can send a decline signal.
  String? declineCall(String callId) {
    final did = _pendingCalls.remove(callId);
    if (_activeCallId == callId) {
      _activeCallId = null;
      _activePeerDid = null;
    }
    return did;
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
      if (entry.value == otherPartyChannelDid) {
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
  String? removePendingByDid(String otherPartyChannelDid) {
    String? callId;
    for (final entry in _pendingCalls.entries) {
      if (entry.value == otherPartyChannelDid) {
        callId = entry.key;
        break;
      }
    }
    if (callId != null) {
      _pendingCalls.remove(callId);
      if (_activeCallId == callId) {
        _activeCallId = null;
        _activePeerDid = null;
      }
    }
    return callId;
  }

  /// Returns the pending caller DID for [callId], or null when it is unknown.
  String? otherPartyChannelDidFor(String callId) => _pendingCalls[callId];
}
