import 'package:meeting_place_chat/src/transport/matrix/outgoing/media_message_room_event.dart';
import 'package:test/test.dart';

void main() {
  group('MediaMessageRoomEvent', () {
    test('uses top-level url for unencrypted media', () {
      final event = MediaMessageRoomEvent(
        senderDid: 'did:test:alice',
        mxcUri: 'mxc://matrix.example.com/media123',
        contentType: 'image/jpeg',
        sizeBytes: 1234,
        filename: 'photo.jpg',
        caption: 'Hello media',
      );

      expect(event.type, 'm.room.message');
      expect(event.content, {
        'msgtype': MediaMsgType.image,
        'body': 'Hello media',
        'info': {'mimetype': 'image/jpeg', 'size': 1234},
        'filename': 'photo.jpg',
        'url': 'mxc://matrix.example.com/media123',
      });
    });

    test('stores encrypted metadata in file field and omits url', () {
      final encryptedFileJson = <String, dynamic>{
        'url': 'mxc://matrix.example.com/media999',
        'key': {
          'kty': 'oct',
          'alg': 'A256CTR',
          'ext': true,
          'k': 'YWJjZA',
          'key_ops': ['encrypt', 'decrypt'],
        },
        'iv': 'MTIzNDU2Nzg5MDEyMzQ1Ng',
        'hashes': {'sha256': 'c2hhMjU2'},
        'v': 'v2',
      };

      final event = MediaMessageRoomEvent(
        senderDid: 'did:test:alice',
        mxcUri: 'mxc://matrix.example.com/media999',
        contentType: 'application/pdf',
        sizeBytes: 4321,
        filename: 'file.pdf',
        encryptedFileJson: encryptedFileJson,
      );

      expect(event.content['msgtype'], MediaMsgType.file);
      expect(event.content['body'], 'file.pdf');
      expect(event.content['filename'], 'file.pdf');
      expect(event.content['info'], {
        'mimetype': 'application/pdf',
        'size': 4321,
      });
      expect(event.content['file'], encryptedFileJson);
      expect(event.content.containsKey('url'), isFalse);
    });
  });
}
