import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:test/test.dart';

void main() {
  group('CallMetadata.buildAttachment', () {
    test('creates call attachment metadata', () {
      final attachment = CallMetadata.buildAttachment(
        mediaType: CallMediaType.video,
        status: CallStatus.calling,
      );

      final call = CallMetadata.maybeOf(attachment);
      expect(CallMetadata.isCall(attachment), isTrue);
      expect(call?.mediaType, CallMediaType.video);
      expect(call?.status, CallStatus.calling);
      expect(call?.durationMs, isNull);
    });

    test('stores duration when provided', () {
      final attachment = CallMetadata.buildAttachment(
        mediaType: CallMediaType.audio,
        status: CallStatus.ended,
        durationMs: 134000,
      );

      final call = CallMetadata.maybeOf(attachment);
      expect(call?.mediaType, CallMediaType.audio);
      expect(call?.status, CallStatus.ended);
      expect(call?.durationMs, 134000);
    });

    test('rejects negative duration', () {
      expect(
        () => CallMetadata.buildAttachment(
          mediaType: CallMediaType.audio,
          status: CallStatus.ended,
          durationMs: -1,
        ),
        throwsArgumentError,
      );
    });
  });

  group('CallMetadata.maybeOf', () {
    test('round-trips JSON metadata', () {
      final attachment = CallMetadata.buildAttachment(
        mediaType: CallMediaType.video,
        status: CallStatus.inProgress,
        durationMs: 5000,
      );

      final decoded = ChatAttachment.fromJson(attachment.toJson());
      final call = CallMetadata.maybeOf(decoded);
      expect(call?.mediaType, CallMediaType.video);
      expect(call?.status, CallStatus.inProgress);
      expect(call?.durationMs, 5000);
    });

    test('returns null for a non-call attachment', () {
      final attachment = ChatAttachment(
        metadata: const {'media_kind': 'voice'},
      );
      expect(CallMetadata.maybeOf(attachment), isNull);
      expect(CallMetadata.isCall(attachment), isFalse);
    });

    test('returns null when status is unknown', () {
      final attachment = ChatAttachment(
        metadata: const {
          'media_kind': 'call',
          'call_media_type': 'video',
          'call_status': 'bogus',
        },
      );
      expect(CallMetadata.maybeOf(attachment), isNull);
    });
  });

  group('CallMetadata.copyWith', () {
    test('replaces status and duration', () {
      final call = CallMetadata(
        mediaType: CallMediaType.audio,
        status: CallStatus.calling,
      );
      final updated = call.copyWith(
        status: CallStatus.ended,
        durationMs: 42000,
      );
      expect(updated.mediaType, CallMediaType.audio);
      expect(updated.status, CallStatus.ended);
      expect(updated.durationMs, 42000);
    });
  });
}
