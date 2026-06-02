import 'dart:convert';

import 'package:meeting_place_chat/src/entity/chat_attachment.dart';
import 'package:meeting_place_chat/src/transport/matrix/outgoing/matrix_room_message_builder.dart';
import 'package:meeting_place_chat/src/transport/matrix/outgoing/media_message_room_event.dart';
import 'package:meeting_place_chat/src/transport/matrix/outgoing/text_message_room_event.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:test/test.dart';

void main() {
  const builder = MatrixRoomMessageBuilder();
  const senderDid = 'did:test:alice';
  const notification = IndividualChannelNotification(
    recipientDid: 'did:test:bob',
    type: 'chat-activity',
  );

  group('MatrixRoomMessageBuilder', () {
    test('builds TextMessageRoomEvent when no attachment', () {
      final result = builder.build(
        senderDid: senderDid,
        text: 'Hello',
        notification: notification,
      );

      expect(result, isA<TextMessageRoomEvent>());
      expect(result.content['body'], 'Hello');
    });

    test('builds MediaMessageRoomEvent for hosted-media attachment', () {
      const mxcUri = 'mxc://matrix.example.com/abc123';
      final attachment = ChatAttachment(
        filename: 'photo.jpg',
        mediaType: 'image/jpeg',
        format: AttachmentFormat.hostedMedia.value,
        byteCount: 1024,
        data: ChatAttachmentData(links: [Uri.parse(mxcUri)]),
      );

      final result = builder.build(
        senderDid: senderDid,
        text: 'Check this out',
        notification: notification,
        attachment: attachment,
      );

      expect(result, isA<MediaMessageRoomEvent>());
      expect(result.content['msgtype'], MediaMsgType.image);
      expect(result.content['url'], mxcUri);
      expect(result.content['body'], 'Check this out');
      expect(result.content['filename'], 'photo.jpg');
    });

    test('includes validated encrypted file metadata', () {
      const mxcUri = 'mxc://matrix.example.com/enc456';
      final encryptedFile = {
        'url': mxcUri,
        'key': {'kty': 'oct', 'alg': 'A256CTR', 'k': 'YWJjZA'},
        'iv': 'MTIzNDU2Nzg5MDEyMzQ1Ng',
        'hashes': {'sha256': 'c2hhMjU2'},
        'v': 'v2',
      };

      final attachment = ChatAttachment(
        filename: 'secret.pdf',
        mediaType: 'application/pdf',
        format: AttachmentFormat.hostedMedia.value,
        byteCount: 2048,
        data: ChatAttachmentData(
          links: [Uri.parse(mxcUri)],
          json: jsonEncode(encryptedFile),
        ),
      );

      final result = builder.build(
        senderDid: senderDid,
        text: '',
        notification: notification,
        attachment: attachment,
      );

      expect(result, isA<MediaMessageRoomEvent>());
      expect(result.content['file'], encryptedFile);
      expect(result.content.containsKey('url'), isFalse);
    });

    test('throws ArgumentError when encrypted metadata is invalid', () {
      const mxcUri = 'mxc://matrix.example.com/bad789';
      final invalidEncryptedFile = {'url': 'https://not-mxc.com/bad'};

      final attachment = ChatAttachment(
        filename: 'file.bin',
        mediaType: 'application/octet-stream',
        format: AttachmentFormat.hostedMedia.value,
        byteCount: 512,
        data: ChatAttachmentData(
          links: [Uri.parse(mxcUri)],
          json: jsonEncode(invalidEncryptedFile),
        ),
      );

      expect(
        () => builder.build(
          senderDid: senderDid,
          text: '',
          notification: notification,
          attachment: attachment,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws when encrypted URL does not match attachment mxc link', () {
      const mxcUri = 'mxc://matrix.example.com/attachment-link';
      final encryptedFile = {
        'url': 'mxc://matrix.example.com/different-url',
        'key': {'kty': 'oct', 'alg': 'A256CTR', 'k': 'YWJjZA'},
        'iv': 'MTIzNDU2Nzg5MDEyMzQ1Ng',
        'hashes': {'sha256': 'c2hhMjU2'},
        'v': 'v2',
      };

      final attachment = ChatAttachment(
        filename: 'mismatch.bin',
        mediaType: 'application/octet-stream',
        format: AttachmentFormat.hostedMedia.value,
        byteCount: 256,
        data: ChatAttachmentData(
          links: [Uri.parse(mxcUri)],
          json: jsonEncode(encryptedFile),
        ),
      );

      expect(
        () => builder.build(
          senderDid: senderDid,
          text: '',
          notification: notification,
          attachment: attachment,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejection error does not leak key material or raw JSON', () {
      const mxcUri = 'mxc://matrix.example.com/leak-test';
      const secretKey = 'SuperSecretKeyMaterial_abc123';
      const secretIv = 'SecretIV_xyz789';
      final encryptedFile = {
        'url': 'https://wrong-scheme.com/bad',
        'key': {'kty': 'oct', 'alg': 'A256CTR', 'k': secretKey},
        'iv': secretIv,
        'hashes': {'sha256': 'hashvalue'},
        'v': 'v2',
      };

      final attachment = ChatAttachment(
        filename: 'secret.bin',
        mediaType: 'application/octet-stream',
        format: AttachmentFormat.hostedMedia.value,
        byteCount: 1024,
        data: ChatAttachmentData(
          links: [Uri.parse(mxcUri)],
          json: jsonEncode(encryptedFile),
        ),
      );

      try {
        builder.build(
          senderDid: senderDid,
          text: '',
          notification: notification,
          attachment: attachment,
        );
        fail('Expected ArgumentError');
        // ignore: avoid_catching_errors
      } on ArgumentError catch (e) {
        final errorString = e.toString();
        expect(errorString, isNot(contains(secretKey)));
        expect(errorString, isNot(contains(secretIv)));
        expect(errorString, isNot(contains('hashvalue')));
        expect(errorString, isNot(contains(jsonEncode(encryptedFile))));
      }
    });

    test('sends unencrypted media when no encryption JSON is present', () {
      const mxcUri = 'mxc://matrix.example.com/plain';
      final attachment = ChatAttachment(
        filename: 'plain.jpg',
        mediaType: 'image/jpeg',
        format: AttachmentFormat.hostedMedia.value,
        byteCount: 500,
        data: ChatAttachmentData(links: [Uri.parse(mxcUri)]),
      );

      final result = builder.build(
        senderDid: senderDid,
        text: 'No encryption',
        notification: notification,
        attachment: attachment,
      );

      expect(result, isA<MediaMessageRoomEvent>());
      expect(result.content['url'], mxcUri);
      expect(result.content.containsKey('file'), isFalse);
    });

    test('falls back to TextMessageRoomEvent for non-hosted attachment', () {
      final attachment = ChatAttachment(
        filename: 'inline.txt',
        mediaType: 'text/plain',
        data: ChatAttachmentData(base64: 'SGVsbG8='),
      );

      final result = builder.build(
        senderDid: senderDid,
        text: 'Inline file',
        notification: notification,
        attachment: attachment,
      );

      expect(result, isA<TextMessageRoomEvent>());
      expect(result.content['body'], 'Inline file');
    });

    test('uses filename as body when caption is empty', () {
      const mxcUri = 'mxc://matrix.example.com/nocap';
      final attachment = ChatAttachment(
        filename: 'document.pdf',
        mediaType: 'application/pdf',
        format: AttachmentFormat.hostedMedia.value,
        byteCount: 100,
        data: ChatAttachmentData(links: [Uri.parse(mxcUri)]),
      );

      final result = builder.build(
        senderDid: senderDid,
        text: '',
        notification: notification,
        attachment: attachment,
      );

      expect(result, isA<MediaMessageRoomEvent>());
      expect(result.content['body'], 'document.pdf');
    });
  });
}
