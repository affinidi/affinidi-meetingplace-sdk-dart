import 'package:meeting_place_chat/src/transport/matrix/outgoing/media_message_room_event.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
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
        encryptedFileFieldUrl: 'mxc://matrix.example.com/media999',
        encryptedFileFieldKey: {
          jsonWebKeyFieldKty: jsonWebKeyType,
          jsonWebKeyFieldAlg: jsonWebKeyAlgorithm,
          jsonWebKeyFieldExt: true,
          jsonWebKeyFieldK: 'YWJjZA',
          jsonWebKeyFieldKeyOps: jsonWebKeyOperations,
        },
        encryptedFileFieldIv: 'MTIzNDU2Nzg5MDEyMzQ1Ng',
        encryptedFileFieldHashes: {encryptedFileSha256Key: 'c2hhMjU2'},
        encryptedFileFieldVersion: encryptedFileInfoVersion,
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
