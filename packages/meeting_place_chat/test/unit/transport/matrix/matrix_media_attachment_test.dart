import 'package:meeting_place_chat/src/transport/matrix/matrix_media_attachment.dart';
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
}
