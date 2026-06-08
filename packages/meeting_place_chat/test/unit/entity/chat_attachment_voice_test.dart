import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:test/test.dart';

void main() {
  group('ChatAttachment.voiceMessage', () {
    test('creates voice attachment metadata', () {
      final attachment = ChatAttachment.voiceMessage(
        base64: 'AAAA',
        durationMs: 1200,
        filename: 'voice.m4a',
        waveform: [0, 50, 100],
      );

      expect(attachment.mediaKind, AttachmentMediaKind.voice);
      expect(attachment.mediaType, ChatAttachment.defaultVoiceMediaType);
      expect(attachment.durationMs, 1200);
      expect(attachment.waveform, [0, 50, 100]);
      expect(attachment.data?.base64, 'AAAA');
    });

    test('round-trips JSON metadata', () {
      final attachment = ChatAttachment.voiceMessage(
        base64: 'AAAA',
        durationMs: 1200,
        waveform: [0, 50, 100],
      );

      final decoded = ChatAttachment.fromJson(attachment.toJson());

      expect(decoded.mediaKind, AttachmentMediaKind.voice);
      expect(decoded.durationMs, 1200);
      expect(decoded.waveform, [0, 50, 100]);
    });

    test('rejects invalid duration and waveform', () {
      expect(
        () => ChatAttachment.voiceMessage(base64: 'AAAA', durationMs: -1),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => ChatAttachment.voiceMessage(
          base64: 'AAAA',
          durationMs: 1,
          waveform: [101],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects empty base64 payload', () {
      expect(
        () => ChatAttachment.voiceMessage(base64: '', durationMs: 1),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
