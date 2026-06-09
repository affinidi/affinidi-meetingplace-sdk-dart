import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:test/test.dart';

void main() {
  group('VoiceMessageMetadata.buildAttachment', () {
    test('creates voice attachment metadata', () {
      final attachment = VoiceMessageMetadata.buildAttachment(
        base64: 'AAAA',
        durationMs: 1200,
        filename: 'voice.m4a',
        waveform: [0, 50, 100],
      );

      final voice = VoiceMessageMetadata.of(attachment);
      expect(VoiceMessageMetadata.isVoice(attachment), isTrue);
      expect(attachment.mediaType, VoiceMessageMetadata.defaultMediaType);
      expect(voice?.durationMs, 1200);
      expect(voice?.waveform, [0, 50, 100]);
      expect(attachment.data?.base64, 'AAAA');
    });

    test('round-trips JSON metadata', () {
      final attachment = VoiceMessageMetadata.buildAttachment(
        base64: 'AAAA',
        durationMs: 1200,
        waveform: [0, 50, 100],
      );

      final decoded = ChatAttachment.fromJson(attachment.toJson());
      final voice = VoiceMessageMetadata.of(decoded);

      expect(VoiceMessageMetadata.isVoice(decoded), isTrue);
      expect(voice?.durationMs, 1200);
      expect(voice?.waveform, [0, 50, 100]);
    });

    test('rejects invalid duration and waveform', () {
      expect(
        () => VoiceMessageMetadata.buildAttachment(
          base64: 'AAAA',
          durationMs: -1,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => VoiceMessageMetadata.buildAttachment(
          base64: 'AAAA',
          durationMs: 1,
          waveform: [101],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects empty base64 payload', () {
      expect(
        () => VoiceMessageMetadata.buildAttachment(base64: '', durationMs: 1),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects non-audio mediaType', () {
      expect(
        () => VoiceMessageMetadata.buildAttachment(
          base64: 'AAAA',
          durationMs: 100,
          mediaType: 'image/png',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('VoiceMessageMetadata.of', () {
    test('returns null for a plain attachment', () {
      final attachment = ChatAttachment(
        filename: 'photo.jpg',
        mediaType: 'image/jpeg',
      );

      expect(VoiceMessageMetadata.isVoice(attachment), isFalse);
      expect(VoiceMessageMetadata.of(attachment), isNull);
    });
  });
}
