import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_matrix/src/call/call_media_type.dart';
import 'package:meeting_place_matrix/src/entity/call_metadata.dart';
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
  });
}
