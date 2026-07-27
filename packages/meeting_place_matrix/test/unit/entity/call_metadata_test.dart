import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_matrix/meeting_place_matrix.dart';
import 'package:test/test.dart';

void main() {
  group('CallMetadata', () {
    const testCallId = 'room123@1234567890';
    const testMediaType = CallMediaType.audio;
    const testStatus = CallStatus.inProgress;

    test('construction requires callId', () {
      final metadata = CallMetadata(
        mediaType: testMediaType,
        status: testStatus,
        callId: testCallId,
      );
      expect(metadata.callId, testCallId);
      expect(metadata.mediaType, testMediaType);
      expect(metadata.status, testStatus);
      expect(metadata.durationMs, isNull);
    });

    test('construction with durationMs', () {
      const duration = 12345;
      final metadata = CallMetadata(
        mediaType: testMediaType,
        status: testStatus,
        callId: testCallId,
        durationMs: duration,
      );
      expect(metadata.durationMs, duration);
    });

    test('toMetadata includes callId', () {
      final metadata = CallMetadata(
        mediaType: testMediaType,
        status: testStatus,
        callId: testCallId,
      );
      final map = metadata.toMetadata();
      expect(map['call_id'], testCallId);
      expect(map['call_media_type'], 'audio');
      expect(map['call_status'], 'inProgress');
      expect(map['media_kind'], 'call');
    });

    test('toMetadata with durationMs', () {
      const duration = 5000;
      final metadata = CallMetadata(
        mediaType: CallMediaType.video,
        status: CallStatus.ended,
        callId: testCallId,
        durationMs: duration,
      );
      final map = metadata.toMetadata();
      expect(map['duration_ms'], duration);
    });

    test('maybeOf returns CallMetadata when callId is present and valid', () {
      final attachment = ChatAttachment(
        id: 'msg-1',
        metadata: {
          'media_kind': 'call',
          'call_media_type': 'audio',
          'call_status': 'inProgress',
          'call_id': testCallId,
        },
      );
      final result = CallMetadata.maybeOf(attachment);
      expect(result, isNotNull);
      expect(result!.callId, testCallId);
      expect(result.mediaType, CallMediaType.audio);
      expect(result.status, CallStatus.inProgress);
    });

    test('maybeOf deserializes with missing callId as empty string', () {
      final attachment = ChatAttachment(
        id: 'msg-1',
        metadata: {
          'media_kind': 'call',
          'call_media_type': 'audio',
          'call_status': 'inProgress',
        },
      );
      final result = CallMetadata.maybeOf(attachment);
      expect(result, isNotNull);
      expect(result!.callId, '');
    });

    test('maybeOf deserializes with empty string callId', () {
      final attachment = ChatAttachment(
        id: 'msg-1',
        metadata: {
          'media_kind': 'call',
          'call_media_type': 'audio',
          'call_status': 'inProgress',
          'call_id': '',
        },
      );
      final result = CallMetadata.maybeOf(attachment);
      expect(result, isNotNull);
      expect(result!.callId, '');
    });

    test('maybeOf returns null when callId is not a string', () {
      final attachment = ChatAttachment(
        id: 'msg-1',
        metadata: {
          'media_kind': 'call',
          'call_media_type': 'audio',
          'call_status': 'inProgress',
          'call_id': 12345,
        },
      );
      final result = CallMetadata.maybeOf(attachment);
      expect(result, isNull);
    });

    test('maybeOf returns null when not a call attachment', () {
      final attachment = ChatAttachment(
        id: 'msg-1',
        metadata: {
          'media_kind': 'voice_message',
          'call_media_type': 'audio',
          'call_status': 'inProgress',
          'call_id': testCallId,
        },
      );
      final result = CallMetadata.maybeOf(attachment);
      expect(result, isNull);
    });

    test('maybeOf with durationMs', () {
      const duration = 3000;
      final attachment = ChatAttachment(
        id: 'msg-1',
        metadata: {
          'media_kind': 'call',
          'call_media_type': 'video',
          'call_status': 'ended',
          'call_id': testCallId,
          'duration_ms': duration,
        },
      );
      final result = CallMetadata.maybeOf(attachment);
      expect(result, isNotNull);
      expect(result!.durationMs, duration);
    });

    test('buildAttachment creates ChatAttachment with callId', () {
      const id = 'msg-2';
      const mediaType = CallMediaType.video;
      const status = CallStatus.calling;
      const callId = 'room456@9876543210';

      final attachment = CallMetadata.buildAttachment(
        mediaType: mediaType,
        status: status,
        id: id,
        callId: callId,
      );

      expect(attachment.id, id);
      final metadata = CallMetadata.maybeOf(attachment);
      expect(metadata, isNotNull);
      expect(metadata!.callId, callId);
      expect(metadata.mediaType, mediaType);
      expect(metadata.status, status);
    });

    test('buildAttachment with durationMs', () {
      const duration = 7500;
      final attachment = CallMetadata.buildAttachment(
        mediaType: CallMediaType.audio,
        status: CallStatus.ended,
        id: 'msg-3',
        callId: testCallId,
        durationMs: duration,
      );
      final metadata = CallMetadata.maybeOf(attachment);
      expect(metadata!.durationMs, duration);
    });

    test('copyWith preserves callId', () {
      final original = CallMetadata(
        mediaType: testMediaType,
        status: testStatus,
        callId: testCallId,
      );
      final copied = original.copyWith(status: CallStatus.ended);
      expect(copied.callId, original.callId);
      expect(copied.status, CallStatus.ended);
      expect(copied.mediaType, original.mediaType);
    });

    test('copyWith updates durationMs', () {
      const originalDuration = 5000;
      const newDuration = 10000;
      final original = CallMetadata(
        mediaType: testMediaType,
        status: testStatus,
        callId: testCallId,
        durationMs: originalDuration,
      );
      final copied = original.copyWith(durationMs: newDuration);
      expect(copied.durationMs, newDuration);
      expect(copied.callId, original.callId);
    });

    test('isCall returns true for call attachments', () {
      final attachment = ChatAttachment(
        id: 'msg-1',
        metadata: {'media_kind': 'call'},
      );
      expect(CallMetadata.isCall(attachment), isTrue);
    });

    test('isCall returns false for non-call attachments', () {
      final attachment = ChatAttachment(
        id: 'msg-1',
        metadata: {'media_kind': 'voice_message'},
      );
      expect(CallMetadata.isCall(attachment), isFalse);
    });

    test('durationMs validation rejects negative values', () {
      expect(
        () => CallMetadata(
          mediaType: testMediaType,
          status: testStatus,
          callId: testCallId,
          durationMs: -1,
        ),
        throwsArgumentError,
      );
    });

    test('durationMs validation accepts zero', () {
      final metadata = CallMetadata(
        mediaType: testMediaType,
        status: testStatus,
        callId: testCallId,
        durationMs: 0,
      );
      expect(metadata.durationMs, 0);
    });

    test('participation is null by default', () {
      final metadata = CallMetadata(
        mediaType: testMediaType,
        status: testStatus,
        callId: testCallId,
      );
      expect(metadata.participation, isNull);
      expect(metadata.toMetadata().containsKey('call_participation'), isFalse);
    });

    test('toMetadata nests the participation block', () {
      final metadata = CallMetadata(
        mediaType: testMediaType,
        status: testStatus,
        callId: testCallId,
        participation: CallParticipation(
          participantCount: 2,
          didSelfJoin: true,
          selfLeftBeforeEnd: true,
          initiatorDid: 'did:peer:initiator',
        ),
      );
      final block = metadata.toMetadata()['call_participation'];
      expect(block, {
        'participant_count': 2,
        'did_self_join': true,
        'self_left_before_end': true,
        'initiator_did': 'did:peer:initiator',
      });
    });

    test('maybeOf round-trips the participation block', () {
      final attachment = CallMetadata.buildAttachment(
        mediaType: testMediaType,
        status: testStatus,
        id: 'msg-group',
        callId: testCallId,
        participation: CallParticipation(
          participantCount: 3,
          didSelfJoin: false,
          selfLeftBeforeEnd: false,
        ),
      );
      final result = CallMetadata.maybeOf(attachment);
      expect(result, isNotNull);
      final participation = result!.participation;
      expect(participation, isNotNull);
      expect(participation!.participantCount, 3);
      expect(participation.didSelfJoin, isFalse);
      expect(participation.selfLeftBeforeEnd, isFalse);
      expect(participation.initiatorDid, isNull);
    });

    test('maybeOf yields null participation for a 1:1 call', () {
      final attachment = ChatAttachment(
        id: 'msg-1',
        metadata: {
          'media_kind': 'call',
          'call_media_type': 'audio',
          'call_status': 'inProgress',
          'call_id': testCallId,
        },
      );
      expect(CallMetadata.maybeOf(attachment)!.participation, isNull);
    });

    test('maybeOf ignores a malformed participation block', () {
      final attachment = ChatAttachment(
        id: 'msg-1',
        metadata: {
          'media_kind': 'call',
          'call_media_type': 'audio',
          'call_status': 'inProgress',
          'call_id': testCallId,
          'call_participation': {'participant_count': 'two'},
        },
      );
      final result = CallMetadata.maybeOf(attachment);
      expect(result, isNotNull);
      expect(result!.participation, isNull);
    });

    test('copyWith replaces the participation block', () {
      final original = CallMetadata(
        mediaType: testMediaType,
        status: testStatus,
        callId: testCallId,
        participation: CallParticipation(
          participantCount: 1,
          didSelfJoin: true,
          selfLeftBeforeEnd: false,
        ),
      );
      final copied = original.copyWith(
        participation: original.participation!.copyWith(participantCount: 4),
      );
      expect(copied.participation!.participantCount, 4);
      expect(copied.participation!.didSelfJoin, isTrue);
    });

    test('participantCount validation rejects negative values', () {
      expect(
        () => CallParticipation(
          participantCount: -1,
          didSelfJoin: true,
          selfLeftBeforeEnd: false,
        ),
        throwsArgumentError,
      );
    });
  });

  group('CallOutcomeRecord', () {
    const testCallId = 'room123@1234567890';
    final startedAt = DateTime.fromMillisecondsSinceEpoch(1000);
    final endedAt = DateTime.fromMillisecondsSinceEpoch(61000);

    test('toMap round-trips through fromMap', () {
      final record = CallOutcomeRecord(
        callId: testCallId,
        outcome: CallOutcome.ended,
        answered: true,
        startedAt: startedAt,
        endedAt: endedAt,
      );
      final parsed = CallOutcomeRecord.fromMap(record.toMap());
      expect(parsed, isNotNull);
      expect(parsed!.callId, testCallId);
      expect(parsed.outcome, CallOutcome.ended);
      expect(parsed.answered, isTrue);
      expect(parsed.startedAt, startedAt);
      expect(parsed.endedAt, endedAt);
    });

    test('toMap omits null timestamps', () {
      final record = const CallOutcomeRecord(
        callId: testCallId,
        outcome: CallOutcome.cancelled,
        answered: false,
      );
      final map = record.toMap();
      expect(map.containsKey('started_at_ms'), isFalse);
      expect(map.containsKey('ended_at_ms'), isFalse);
    });

    test('fromMap tolerates an absent endedAt so the receiver can supply the '
        'authoritative server timestamp', () {
      final record = CallOutcomeRecord(
        callId: testCallId,
        outcome: CallOutcome.ended,
        answered: true,
        startedAt: startedAt,
      );
      final parsed = CallOutcomeRecord.fromMap(record.toMap());
      expect(parsed, isNotNull);
      expect(parsed!.endedAt, isNull);
      expect(parsed.startedAt, startedAt);
    });

    test('fromMap returns null on a missing callId', () {
      final parsed = CallOutcomeRecord.fromMap({
        'outcome': 'ended',
        'answered': true,
      });
      expect(parsed, isNull);
    });

    test('fromMap returns null on an unknown outcome', () {
      final parsed = CallOutcomeRecord.fromMap({
        'call_id': testCallId,
        'outcome': 'exploded',
        'answered': true,
      });
      expect(parsed, isNull);
    });

    test('fromMap returns null when answered is missing', () {
      final parsed = CallOutcomeRecord.fromMap({
        'call_id': testCallId,
        'outcome': 'ended',
      });
      expect(parsed, isNull);
    });

    test('fromMap returns null on a non-map value', () {
      expect(CallOutcomeRecord.fromMap('nope'), isNull);
    });

    test('copyWith replaces the endedAt', () {
      final record = CallOutcomeRecord(
        callId: testCallId,
        outcome: CallOutcome.ended,
        answered: true,
        startedAt: startedAt,
      );
      final withEnd = record.copyWith(endedAt: endedAt);
      expect(withEnd.endedAt, endedAt);
      expect(withEnd.startedAt, startedAt);
      expect(withEnd.callId, testCallId);
    });
  });
}
