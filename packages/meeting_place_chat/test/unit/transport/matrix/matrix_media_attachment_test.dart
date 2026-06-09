import 'package:meeting_place_chat/src/transport/matrix/matrix_media_attachment.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:test/test.dart';

void main() {
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
    });
  });
}
