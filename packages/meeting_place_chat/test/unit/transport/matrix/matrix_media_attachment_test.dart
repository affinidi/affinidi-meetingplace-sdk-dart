import 'dart:typed_data';

import 'package:matrix/matrix.dart' as matrix;
import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_chat/src/transport/matrix/matrix_media_attachment.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:test/test.dart';

void main() {
  group('Matrix audio MIME handling', () {
    test('audio/mp4 maps to Matrix m.audio content', () {
      final file = matrix.MatrixFile.fromMimeType(
        bytes: Uint8List(1),
        name: 'voice.m4a',
        mimeType: AttachmentMediaType.audioMp4.value,
      );

      expect(file.msgType, MediaMsgType.audio);
      expect(file.info['mimetype'], AttachmentMediaType.audioMp4.value);
    });

    test('audio/wav maps to Matrix m.audio content', () {
      final file = matrix.MatrixFile.fromMimeType(
        bytes: Uint8List(1),
        name: 'voice.wav',
        mimeType: AttachmentMediaType.audioWav.value,
      );

      expect(file.msgType, MediaMsgType.audio);
      expect(file.info['mimetype'], AttachmentMediaType.audioWav.value);
    });
  });

  group('MatrixMediaAttachments.extractCaption', () {
    test('returns null for non-media msgtype', () {
      expect(
        MatrixMediaAttachments.extractCaption({
          'msgtype': 'm.text',
          'body': 'hello',
        }),
        isNull,
      );
    });

    test('returns empty string when filename is absent', () {
      expect(
        MatrixMediaAttachments.extractCaption({
          'msgtype': 'm.image',
          'body': 'photo.jpg',
        }),
        isEmpty,
      );
    });

    test('returns empty string when body equals filename', () {
      expect(
        MatrixMediaAttachments.extractCaption({
          'msgtype': 'm.image',
          'body': 'photo.jpg',
          'filename': 'photo.jpg',
        }),
        isEmpty,
      );
    });

    test('returns body as caption when it differs from filename', () {
      expect(
        MatrixMediaAttachments.extractCaption({
          'msgtype': 'm.image',
          'body': 'check this out',
          'filename': 'photo.jpg',
        }),
        'check this out',
      );
    });

    test('returns empty string for raw msgtype placeholder body', () {
      expect(
        MatrixMediaAttachments.extractCaption({
          'msgtype': 'm.image',
          'body': 'm.image',
        }),
        isEmpty,
      );
    });
  });

  group('MatrixMediaAttachments.extractFromContent', () {
    test('returns empty list for non-media msgtype', () {
      expect(
        MatrixMediaAttachments.extractFromContent({
          'msgtype': 'm.text',
          'body': 'hello',
        }),
        isEmpty,
      );
    });

    test('returns display-only metadata without mxc URI or encryption', () {
      final attachments = MatrixMediaAttachments.extractFromContent({
        'msgtype': 'm.image',
        'body': 'photo.jpg',
        'filename': 'photo.jpg',
        'url': 'mxc://matrix.example.com/abc123',
        'file': {
          'url': 'mxc://matrix.example.com/abc123',
          'key': {'kty': 'oct', 'alg': 'A256CTR', 'k': 'secret'},
          'iv': 'iv-bytes',
          'hashes': {'sha256': 'hash-bytes'},
          'v': 'v2',
        },
        'info': {'mimetype': 'image/jpeg', 'size': 12345},
      });

      expect(attachments, hasLength(1));
      final a = attachments.single;
      expect(a.id, isNotEmpty);
      expect(a.format, AttachmentFormat.hostedMedia.value);
      expect(a.filename, 'photo.jpg');
      expect(a.mediaType, 'image/jpeg');
      expect(a.byteCount, 12345);
      // mxc URI / encryption metadata must not leak into ChatAttachment.
      expect(a.data, isNull);
    });

    test('falls back to body when filename is absent', () {
      final attachments = MatrixMediaAttachments.extractFromContent({
        'msgtype': 'm.file',
        'body': 'document.pdf',
        'url': 'mxc://matrix.example.com/xyz',
        'info': {'mimetype': 'application/pdf', 'size': 100},
      });

      expect(attachments.single.filename, 'document.pdf');
      expect(attachments.single.id, isNotEmpty);
    });

    test('extracts voice metadata from Matrix audio info', () {
      final attachments = MatrixMediaAttachments.extractFromContent({
        'msgtype': 'm.audio',
        'body': 'voice.m4a',
        'filename': 'voice.m4a',
        'info': {'mimetype': 'audio/mp4', 'size': 4096, 'duration': 1200},
        MatrixMediaAttachments.voiceContentKey: <String, dynamic>{},
        MatrixMediaAttachments.audioContentKey: {
          'duration': 1200,
          'waveform': [0, 40, 100],
        },
      });

      final attachment = attachments.single;
      final voice = VoiceMessageMetadata.of(attachment);
      expect(attachment.id, isNotEmpty);
      expect(attachment.mediaType, AttachmentMediaType.audioMp4.value);
      expect(VoiceMessageMetadata.isVoice(attachment), isTrue);
      expect(voice?.durationMs, 1200);
      expect(voice?.waveform, [0, 40, 100]);
    });

    test('keeps generic audio generic without voice metadata', () {
      final attachments = MatrixMediaAttachments.extractFromContent({
        'msgtype': 'm.audio',
        'body': 'track.mp3',
        'info': {'mimetype': 'audio/mpeg', 'size': 4096, 'duration': 1200},
      });

      final attachment = attachments.single;
      expect(attachment.id, isNotEmpty);
      expect(attachment.mediaType, AttachmentMediaType.audioMpeg.value);
      expect(VoiceMessageMetadata.isVoice(attachment), isFalse);
      expect(attachment.metadata, isNull);
    });

    test('ignores malformed voice waveform values', () {
      final attachments = MatrixMediaAttachments.extractFromContent({
        'msgtype': 'm.audio',
        'body': 'voice.m4a',
        'info': {'mimetype': 'audio/mp4'},
        MatrixMediaAttachments.voiceContentKey: <String, dynamic>{},
        MatrixMediaAttachments.audioContentKey: {
          'waveform': [0, 101],
        },
      });

      final attachment = attachments.single;
      expect(attachment.id, isNotEmpty);
      expect(VoiceMessageMetadata.isVoice(attachment), isTrue);
      expect(VoiceMessageMetadata.of(attachment)?.waveform, isNull);
    });
  });

  group('MatrixMediaAttachments metadata attachments round-trip', () {
    test('build then extract preserves id and metadata', () {
      final call = CallMetadata.buildAttachment(
        mediaType: CallMediaType.video,
        status: CallStatus.calling,
        id: 'call-1',
      );

      final content = {
        'msgtype': 'm.text',
        'body': '',
        MatrixEventField.attachmentsMetadata:
            MatrixMediaAttachments.buildMetadataAttachmentsContent([call]),
      };

      final extracted = MatrixMediaAttachments.extractMetadataAttachments(
        content,
      );

      expect(extracted, hasLength(1));
      expect(extracted.single.id, 'call-1');
      expect(CallMetadata.isCall(extracted.single), isTrue);
      final meta = CallMetadata.maybeOf(extracted.single);
      expect(meta?.mediaType, CallMediaType.video);
      expect(meta?.status, CallStatus.calling);
    });

    test('returns empty list when content has no metadata attachments', () {
      expect(
        MatrixMediaAttachments.extractMetadataAttachments({
          'msgtype': 'm.text',
          'body': 'hello',
        }),
        isEmpty,
      );
    });

    test('extractFromContent ignores metadata-only call content', () {
      final content = {
        'msgtype': 'm.text',
        'body': '',
        MatrixEventField.attachmentsMetadata:
            MatrixMediaAttachments.buildMetadataAttachmentsContent([
              CallMetadata.buildAttachment(
                mediaType: CallMediaType.audio,
                status: CallStatus.calling,
              ),
            ]),
      };

      expect(MatrixMediaAttachments.extractFromContent(content), isEmpty);
    });
  });
}
