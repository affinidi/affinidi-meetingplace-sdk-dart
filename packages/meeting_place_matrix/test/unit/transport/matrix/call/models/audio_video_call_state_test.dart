import 'package:meeting_place_core/meeting_place_core.dart' show ContactCard;
import 'package:meeting_place_matrix/src/transport/matrix/call/models/audio_video_call_error_code.dart';
import 'package:meeting_place_matrix/src/transport/matrix/call/models/audio_video_call_participant.dart';
import 'package:meeting_place_matrix/src/transport/matrix/call/models/audio_video_call_state.dart';
import 'package:meeting_place_matrix/src/transport/matrix/call/models/audio_video_call_status.dart';
import 'package:meeting_place_matrix/src/transport/matrix/call/models/call_role.dart';
import 'package:test/test.dart';

void main() {
  group('AudioVideoCallState', () {
    const testCallId = 'room123@1234567890';
    final testCallStartedAt = DateTime(2026, 1, 1, 12, 0, 0);

    test('initial state has default values', () {
      const state = AudioVideoCallState.initial;
      expect(state.status, AudioVideoCallStatus.idle);
      expect(state.participants, isEmpty);
      expect(state.errorCode, isNull);
      expect(state.ownRole, isNull);
      expect(state.callId, isNull);
      expect(state.callStartedAt, isNull);
      expect(state.participantContactCardsByDid, isEmpty);
    });

    test('construction with callId', () {
      const state = AudioVideoCallState(callId: testCallId);
      expect(state.callId, testCallId);
      expect(state.status, AudioVideoCallStatus.idle);
    });

    test('construction with all fields', () {
      final state = AudioVideoCallState(
        status: AudioVideoCallStatus.active,
        participants: const [],
        errorCode: null,
        ownRole: CallRole.caller,
        callId: testCallId,
        callStartedAt: testCallStartedAt,
      );
      expect(state.status, AudioVideoCallStatus.active);
      expect(state.ownRole, CallRole.caller);
      expect(state.callId, testCallId);
      expect(state.callStartedAt, testCallStartedAt);
    });

    test('copyWith preserves callId when not specified', () {
      const state = AudioVideoCallState(
        status: AudioVideoCallStatus.idle,
        callId: testCallId,
      );
      final copied = state.copyWith(
        status: AudioVideoCallStatus.outgoingRinging,
      );
      expect(copied.callId, testCallId);
      expect(copied.status, AudioVideoCallStatus.outgoingRinging);
    });

    test('copyWith updates callId when specified', () {
      const oldCallId = 'room123@1000000000';
      const newCallId = 'room456@2000000000';
      const state = AudioVideoCallState(callId: oldCallId);
      final copied = state.copyWith(callId: newCallId);
      expect(copied.callId, newCallId);
    });

    test('copyWith can set callId from null', () {
      const state = AudioVideoCallState(callId: null);
      final copied = state.copyWith(callId: testCallId);
      expect(copied.callId, testCallId);
    });

    test('copyWith updates status', () {
      const state = AudioVideoCallState(status: AudioVideoCallStatus.idle);
      final copied = state.copyWith(
        status: AudioVideoCallStatus.outgoingRinging,
      );
      expect(copied.status, AudioVideoCallStatus.outgoingRinging);
    });

    test('copyWith updates ownRole', () {
      const state = AudioVideoCallState(ownRole: null);
      final copied = state.copyWith(ownRole: CallRole.caller);
      expect(copied.ownRole, CallRole.caller);
    });

    test('copyWith updates callStartedAt', () {
      const state = AudioVideoCallState(callStartedAt: null);
      final copied = state.copyWith(callStartedAt: testCallStartedAt);
      expect(copied.callStartedAt, testCallStartedAt);
    });

    test('copyWith preserves other fields', () {
      const participant = AudioVideoCallParticipant(
        participantId: 'participant-1',
      );
      final state = AudioVideoCallState(
        status: AudioVideoCallStatus.active,
        participants: [participant],
        ownRole: CallRole.caller,
        callId: testCallId,
        callStartedAt: testCallStartedAt,
      );
      final copied = state.copyWith(status: AudioVideoCallStatus.ended);
      expect(copied.participants, [participant]);
      expect(copied.ownRole, CallRole.caller);
      expect(copied.callId, testCallId);
      expect(copied.callStartedAt, testCallStartedAt);
    });

    test('copyWith updates errorCode', () {
      const state = AudioVideoCallState(errorCode: null);
      final copied = state.copyWith(
        errorCode: AudioVideoCallErrorCode.connectionFailed,
      );
      expect(copied.errorCode, AudioVideoCallErrorCode.connectionFailed);
    });

    test('copyWith clears errorCode with clearErrorCode flag', () {
      const state = AudioVideoCallState(
        errorCode: AudioVideoCallErrorCode.connectionFailed,
      );
      final copied = state.copyWith(clearErrorCode: true);
      expect(copied.errorCode, isNull);
    });

    test('copyWith preserves errorCode when clearErrorCode is false', () {
      const error = AudioVideoCallErrorCode.connectionFailed;
      const state = AudioVideoCallState(errorCode: error);
      final copied = state.copyWith(
        errorCode: AudioVideoCallErrorCode.callInviteFailed,
        clearErrorCode: false,
      );
      expect(copied.errorCode, AudioVideoCallErrorCode.callInviteFailed);
    });

    test('clearErrorCode takes precedence over errorCode', () {
      const state = AudioVideoCallState(
        errorCode: AudioVideoCallErrorCode.connectionFailed,
      );
      final copied = state.copyWith(
        errorCode: AudioVideoCallErrorCode.callInviteFailed,
        clearErrorCode: true,
      );
      expect(copied.errorCode, isNull);
    });

    test('copyWith updates participants', () {
      const participant1 = AudioVideoCallParticipant(
        participantId: 'participant-1',
      );
      const participant2 = AudioVideoCallParticipant(
        participantId: 'participant-2',
      );
      const state = AudioVideoCallState(participants: []);
      final copied = state.copyWith(participants: [participant1, participant2]);
      expect(copied.participants, [participant1, participant2]);
    });

    test('copyWith updates participant contact cards', () {
      final card = ContactCard(
        did: 'did:test:alice',
        type: 'individual',
        contactInfo: {'name': 'Alice'},
      );
      const state = AudioVideoCallState();
      final copied = state.copyWith(
        participantContactCardsByDid: {'did:test:alice': card},
      );
      expect(copied.participantContactCardsByDid['did:test:alice'], same(card));
    });

    test('copyWith preserves participants when not specified', () {
      const participant = AudioVideoCallParticipant(
        participantId: 'participant-1',
      );
      const state = AudioVideoCallState(participants: [participant]);
      final copied = state.copyWith(status: AudioVideoCallStatus.ended);
      expect(copied.participants, [participant]);
    });

    test('callId and callStartedAt move together', () {
      final state1 = AudioVideoCallState(
        callId: testCallId,
        callStartedAt: testCallStartedAt,
      );
      final state2 = state1.copyWith(status: AudioVideoCallStatus.active);
      expect(state2.callId, testCallId);
      expect(state2.callStartedAt, testCallStartedAt);
    });

    test('multiple copyWith chains preserve callId', () {
      const initial = AudioVideoCallState(callId: testCallId);
      final step1 = initial.copyWith(
        status: AudioVideoCallStatus.outgoingRinging,
      );
      final step2 = step1.copyWith(ownRole: CallRole.caller);
      final step3 = step2.copyWith(status: AudioVideoCallStatus.active);
      expect(step3.callId, testCallId);
      expect(step3.status, AudioVideoCallStatus.active);
      expect(step3.ownRole, CallRole.caller);
    });

    test('copyWith all parameters at once', () {
      const participant = AudioVideoCallParticipant(
        participantId: 'participant-1',
      );
      const state = AudioVideoCallState(
        status: AudioVideoCallStatus.idle,
        participants: [],
        errorCode: null,
        ownRole: null,
        callId: null,
        callStartedAt: null,
      );
      final copied = state.copyWith(
        status: AudioVideoCallStatus.active,
        participants: [participant],
        ownRole: CallRole.recipient,
        callId: testCallId,
        callStartedAt: testCallStartedAt,
      );
      expect(copied.status, AudioVideoCallStatus.active);
      expect(copied.participants, [participant]);
      expect(copied.ownRole, CallRole.recipient);
      expect(copied.callId, testCallId);
      expect(copied.callStartedAt, testCallStartedAt);
    });
  });
}
