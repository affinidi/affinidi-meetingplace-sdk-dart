import 'package:meeting_place_matrix/meeting_place_matrix.dart';
import 'package:meeting_place_matrix/src/managers/pending_call_manager.dart';
import 'package:test/test.dart';

const _callId = 'call-001';
const _otherPartyDid = 'did:key:other-party';
const _otherPartyDid2 = 'did:key:other-party-2';
const _mediaType = CallMediaType.video;

void main() {
  late PendingCallManager manager;

  setUp(() => manager = PendingCallManager());

  group('isBusy', () {
    test('is false initially', () {
      expect(manager.isBusy, isFalse);
    });

    test('is true after registerIncomingCall', () {
      manager.registerIncomingCall(
        callId: _callId,
        otherPartyChannelDid: _otherPartyDid,
        mediaType: _mediaType,
      );
      expect(manager.isBusy, isTrue);
    });

    test('is false after declineCall clears the active call', () {
      manager.registerIncomingCall(
        callId: _callId,
        otherPartyChannelDid: _otherPartyDid,
        mediaType: _mediaType,
      );
      manager.declineCall(_callId);
      expect(manager.isBusy, isFalse);
    });
  });

  group('isRinging', () {
    test('is false initially', () {
      expect(manager.isRinging(_callId), isFalse);
    });

    test('is true after registerIncomingCall for that callId', () {
      manager.registerIncomingCall(
        callId: _callId,
        otherPartyChannelDid: _otherPartyDid,
        mediaType: _mediaType,
      );
      expect(manager.isRinging(_callId), isTrue);
    });

    test('is false for a different callId', () {
      manager.registerIncomingCall(
        callId: _callId,
        otherPartyChannelDid: _otherPartyDid,
        mediaType: _mediaType,
      );
      expect(manager.isRinging('other-call'), isFalse);
    });

    test('is false after the call is declined', () {
      manager.registerIncomingCall(
        callId: _callId,
        otherPartyChannelDid: _otherPartyDid,
        mediaType: _mediaType,
      );
      manager.declineCall(_callId);
      expect(manager.isRinging(_callId), isFalse);
    });
  });

  group('registerIncomingCall', () {
    test('returns true and registers the call when not busy', () {
      final result = manager.registerIncomingCall(
        callId: _callId,
        otherPartyChannelDid: _otherPartyDid,
        mediaType: _mediaType,
      );
      expect(result, isTrue);
      expect(manager.isBusy, isTrue);
    });

    test('returns false and does not register when already busy', () {
      manager.registerIncomingCall(
        callId: _callId,
        otherPartyChannelDid: _otherPartyDid,
        mediaType: _mediaType,
      );
      final result = manager.registerIncomingCall(
        callId: 'call-002',
        otherPartyChannelDid: _otherPartyDid2,
        mediaType: CallMediaType.audio,
      );
      expect(result, isFalse);
    });
  });

  group('acceptCall', () {
    test('returns otherPartyChannelDid and removes from pending', () {
      manager.registerIncomingCall(
        callId: _callId,
        otherPartyChannelDid: _otherPartyDid,
        mediaType: _mediaType,
      );
      final did = manager.acceptCall(_callId);
      expect(did, _otherPartyDid);
    });

    test('returns null for unknown callId', () {
      expect(manager.acceptCall('unknown'), isNull);
    });

    test(
      'marks the DID as accepted so resolveRole returns isRecipient=true',
      () {
        manager.registerIncomingCall(
          callId: _callId,
          otherPartyChannelDid: _otherPartyDid,
          mediaType: _mediaType,
        );
        manager.acceptCall(_callId);
        final (:isRecipient, pendingCallId: _) = manager.resolveRole(
          _otherPartyDid,
        );
        expect(isRecipient, isTrue);
      },
    );
  });

  group('declineCall', () {
    test('returns otherPartyChannelDid and clears busy guard', () {
      manager.registerIncomingCall(
        callId: _callId,
        otherPartyChannelDid: _otherPartyDid,
        mediaType: _mediaType,
      );
      final did = manager.declineCall(_callId);
      expect(did, _otherPartyDid);
      expect(manager.isBusy, isFalse);
    });

    test('returns null for unknown callId', () {
      expect(manager.declineCall('unknown'), isNull);
    });
  });

  group('resolveRole', () {
    test('returns isRecipient=false and no pendingCallId for unknown DID', () {
      final (:isRecipient, :pendingCallId) = manager.resolveRole(
        _otherPartyDid,
      );
      expect(isRecipient, isFalse);
      expect(pendingCallId, isNull);
    });

    test('returns isRecipient=true and pendingCallId when call is pending', () {
      manager.registerIncomingCall(
        callId: _callId,
        otherPartyChannelDid: _otherPartyDid,
        mediaType: _mediaType,
      );
      final (:isRecipient, :pendingCallId) = manager.resolveRole(
        _otherPartyDid,
      );
      expect(isRecipient, isTrue);
      expect(pendingCallId, _callId);
    });

    test('removes the pending call after resolving', () {
      manager.registerIncomingCall(
        callId: _callId,
        otherPartyChannelDid: _otherPartyDid,
        mediaType: _mediaType,
      );
      manager.resolveRole(_otherPartyDid);
      final (:isRecipient, pendingCallId: _) = manager.resolveRole(
        _otherPartyDid,
      );
      expect(isRecipient, isFalse);
    });
  });

  group('removePendingByDid', () {
    test('returns callId and clears busy guard when call is pending', () {
      manager.registerIncomingCall(
        callId: _callId,
        otherPartyChannelDid: _otherPartyDid,
        mediaType: _mediaType,
      );
      final pendingCall = manager.removePendingByDid(_otherPartyDid);
      expect(pendingCall?.callId, _callId);
      expect(pendingCall?.mediaType, _mediaType);
      expect(manager.isBusy, isFalse);
    });

    test('returns null for unknown DID', () {
      expect(manager.removePendingByDid('did:key:unknown'), isNull);
    });

    test(
      'does not affect busy guard when removed call was not the active one',
      () {
        manager.registerIncomingCall(
          callId: _callId,
          otherPartyChannelDid: _otherPartyDid,
          mediaType: _mediaType,
        );
        // Decline first call so a different one can become active.
        manager.declineCall(_callId);
        manager.registerIncomingCall(
          callId: 'call-002',
          otherPartyChannelDid: _otherPartyDid2,
          mediaType: CallMediaType.audio,
        );
        // Remove a stale entry that was already declined (no longer in pending)
        final pendingCall = manager.removePendingByDid(_otherPartyDid);
        expect(pendingCall, isNull);
        expect(manager.isBusy, isTrue);
      },
    );
  });

  group('isInCallWith', () {
    test('is false initially', () {
      expect(manager.isInCallWith(_otherPartyDid), isFalse);
    });

    test('is true after registerIncomingCall with that DID', () {
      manager.registerIncomingCall(
        callId: _callId,
        otherPartyChannelDid: _otherPartyDid,
        mediaType: _mediaType,
      );
      expect(manager.isInCallWith(_otherPartyDid), isTrue);
    });

    test('is false for a different DID even when busy', () {
      manager.registerIncomingCall(
        callId: _callId,
        otherPartyChannelDid: _otherPartyDid,
        mediaType: _mediaType,
      );
      expect(manager.isInCallWith(_otherPartyDid2), isFalse);
    });

    test('is true after markOutboundCall with that DID', () {
      manager.markOutboundCall(_otherPartyDid);
      expect(manager.isInCallWith(_otherPartyDid), isTrue);
    });

    test('is false after clearActiveCall', () {
      manager.markOutboundCall(_otherPartyDid);
      manager.clearActiveCall();
      expect(manager.isInCallWith(_otherPartyDid), isFalse);
    });
  });

  group('markOutboundCall', () {
    test('sets isBusy to true', () {
      manager.markOutboundCall(_otherPartyDid);
      expect(manager.isBusy, isTrue);
    });
  });

  group('clearActiveCall', () {
    test('clears busy guard set by markOutboundCall', () {
      manager.markOutboundCall(_otherPartyDid);
      manager.clearActiveCall();
      expect(manager.isBusy, isFalse);
    });

    test('clears busy guard set by registerIncomingCall after accept', () {
      manager.registerIncomingCall(
        callId: _callId,
        otherPartyChannelDid: _otherPartyDid,
        mediaType: _mediaType,
      );
      manager.acceptCall(_callId);
      manager.clearActiveCall();
      expect(manager.isBusy, isFalse);
      expect(manager.isInCallWith(_otherPartyDid), isFalse);
    });
  });

  group('preemptive decline', () {
    test('consume returns false when nothing was recorded', () {
      expect(manager.consumePreemptiveDecline(_otherPartyDid), isFalse);
    });

    test('consume returns true within the window then clears the record', () {
      manager.recordPreemptiveDecline(_otherPartyDid);
      expect(manager.consumePreemptiveDecline(_otherPartyDid), isTrue);
      expect(manager.consumePreemptiveDecline(_otherPartyDid), isFalse);
    });

    test('consume returns false for a different peer', () {
      manager.recordPreemptiveDecline(_otherPartyDid);
      expect(manager.consumePreemptiveDecline(_otherPartyDid2), isFalse);
    });

    test('consume returns false once the window has elapsed', () {
      var now = DateTime(2026);
      final windowed = PendingCallManager(
        preemptiveDeclineWindow: const Duration(seconds: 60),
        now: () => now,
      );
      windowed.recordPreemptiveDecline(_otherPartyDid);
      now = now.add(const Duration(seconds: 61));
      expect(windowed.consumePreemptiveDecline(_otherPartyDid), isFalse);
    });
  });
}
