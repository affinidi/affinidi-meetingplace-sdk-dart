import 'package:flutter_test/flutter_test.dart';
import 'package:meeting_place_matrix_livekit/src/pending_call_manager.dart';

const _callId = 'call-001';
const _otherPartyDid = 'did:key:other-party';
const _otherPartyDid2 = 'did:key:other-party-2';

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
      );
      expect(manager.isBusy, isTrue);
    });

    test('is false after declineCall clears the active call', () {
      manager.registerIncomingCall(
        callId: _callId,
        otherPartyChannelDid: _otherPartyDid,
      );
      manager.declineCall(_callId);
      expect(manager.isBusy, isFalse);
    });
  });

  group('registerIncomingCall', () {
    test('returns true and registers the call when not busy', () {
      final result = manager.registerIncomingCall(
        callId: _callId,
        otherPartyChannelDid: _otherPartyDid,
      );
      expect(result, isTrue);
      expect(manager.isBusy, isTrue);
    });

    test('returns false and does not register when already busy', () {
      manager.registerIncomingCall(
        callId: _callId,
        otherPartyChannelDid: _otherPartyDid,
      );
      final result = manager.registerIncomingCall(
        callId: 'call-002',
        otherPartyChannelDid: _otherPartyDid2,
      );
      expect(result, isFalse);
    });
  });

  group('acceptCall', () {
    test('returns otherPartyChannelDid and removes from pending', () {
      manager.registerIncomingCall(
        callId: _callId,
        otherPartyChannelDid: _otherPartyDid,
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
      );
      final callId = manager.removePendingByDid(_otherPartyDid);
      expect(callId, _callId);
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
        );
        // Decline first call so a different one can become active.
        manager.declineCall(_callId);
        manager.registerIncomingCall(
          callId: 'call-002',
          otherPartyChannelDid: _otherPartyDid2,
        );
        // Remove a stale entry that was already declined (no longer in pending)
        final callId = manager.removePendingByDid(_otherPartyDid);
        expect(callId, isNull);
        expect(manager.isBusy, isTrue);
      },
    );
  });
}
