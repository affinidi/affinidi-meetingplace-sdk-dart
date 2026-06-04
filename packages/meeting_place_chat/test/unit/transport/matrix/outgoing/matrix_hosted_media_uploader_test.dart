import 'dart:convert';
import 'dart:typed_data';

import 'package:meeting_place_chat/src/entity/chat_attachment.dart';
import 'package:meeting_place_chat/src/transport/matrix/outgoing/matrix_hosted_media_uploader.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../../_helpers/mocks.dart';

void main() {
  late MockCoreSDK coreSDK;
  late MatrixHostedMediaUploader uploader;

  const senderDid = 'did:test:alice';
  const mxcUri = 'mxc://matrix.example.com/uploaded123';

  setUp(() {
    coreSDK = MockCoreSDK();
    uploader = MatrixHostedMediaUploader(
      coreSDK: coreSDK,
      senderDid: senderDid,
    );

    registerFallbackValue(Uint8List(0));
  });

  Attachment hostedAttachment({
    String? filename,
    String? mediaType,
    int? byteCount,
  }) {
    return Attachment(
      id: 'uploaded-id',
      filename: filename,
      mediaType: mediaType ?? 'image/jpeg',
      format: AttachmentFormat.hostedMedia.value,
      byteCount: byteCount ?? 160,
      data: AttachmentData(
        links: [Uri.parse(mxcUri)],
        json: jsonEncode({
          'url': mxcUri,
          'key': {'kty': 'oct', 'alg': 'A256CTR', 'k': 'YWJjZA'},
          'iv': 'MTIzNDU2Nzg5MDEyMzQ1Ng',
          'hashes': {'sha256': 'c2hhMjU2'},
          'v': 'v2',
        }),
        hash: 'c2hhMjU2',
      ),
    );
  }

  group('MatrixHostedMediaUploader', () {
    group('prepare', () {
      test('passes through already-hosted attachment unchanged', () async {
        final hosted = ChatAttachment(
          id: 'existing-id',
          description: 'Already hosted',
          filename: 'photo.jpg',
          mediaType: 'image/jpeg',
          format: AttachmentFormat.hostedMedia.value,
          data: ChatAttachmentData(links: [Uri.parse(mxcUri)]),
        );

        final result = await uploader.prepare(hosted);
        expect(result, same(hosted));
        verifyNever(
          () => coreSDK.uploadMedia(
            any(),
            senderDid: any(named: 'senderDid'),
            contentType: any(named: 'contentType'),
            filename: any(named: 'filename'),
          ),
        );
      });

      test('throws ArgumentError when no base64 and no mxc URI', () async {
        final empty = ChatAttachment(
          id: 'empty-id',
          filename: 'empty.txt',
          data: ChatAttachmentData(),
        );

        expect(() => uploader.prepare(empty), throwsA(isA<ArgumentError>()));
      });

      test('strips data-URI prefix before uploading', () async {
        when(
          () => coreSDK.uploadMedia(
            any(),
            senderDid: any(named: 'senderDid'),
            contentType: any(named: 'contentType'),
            filename: any(named: 'filename'),
          ),
        ).thenAnswer((_) async => hostedAttachment());

        final attachment = ChatAttachment(
          id: 'input-id',
          filename: 'photo.jpg',
          mediaType: 'image/jpeg',
          data: ChatAttachmentData(
            base64: 'data:image/jpeg;base64,/9j/4AAQSkZJRg==',
          ),
        );

        await uploader.prepare(attachment);

        final captured = verify(
          () => coreSDK.uploadMedia(
            captureAny(),
            senderDid: senderDid,
            contentType: 'image/jpeg',
            filename: 'photo.jpg',
          ),
        ).captured;

        final decoded = base64Decode(
          const Base64Codec().normalize('/9j/4AAQSkZJRg=='),
        );
        expect(captured.single, decoded);
      });

      test('strips data-URI with extra parameters', () async {
        when(
          () => coreSDK.uploadMedia(
            any(),
            senderDid: any(named: 'senderDid'),
            contentType: any(named: 'contentType'),
            filename: any(named: 'filename'),
          ),
        ).thenAnswer((_) async => hostedAttachment());

        final attachment = ChatAttachment(
          id: 'input-id',
          filename: 'doc.pdf',
          mediaType: 'application/pdf',
          data: ChatAttachmentData(
            base64: 'data:application/pdf;name=doc.pdf;base64,AAAA',
          ),
        );

        await uploader.prepare(attachment);

        final captured = verify(
          () => coreSDK.uploadMedia(
            captureAny(),
            senderDid: senderDid,
            contentType: 'application/pdf',
            filename: 'doc.pdf',
          ),
        ).captured;

        final decoded = base64Decode(const Base64Codec().normalize('AAAA'));
        expect(captured.single, decoded);
      });

      test('preserves caller-owned metadata after upload', () async {
        when(
          () => coreSDK.uploadMedia(
            any(),
            senderDid: any(named: 'senderDid'),
            contentType: any(named: 'contentType'),
            filename: any(named: 'filename'),
          ),
        ).thenAnswer((_) async => hostedAttachment());

        final lastModified = DateTime.utc(2024, 6, 15, 12, 30);
        final attachment = ChatAttachment(
          id: 'input-id',
          description: 'User-provided description',
          filename: 'vacation.jpg',
          mediaType: 'image/jpeg',
          lastModifiedTime: lastModified,
          byteCount: 9999,
          data: ChatAttachmentData(base64: '/9j/4AAQSkZJRg=='),
        );

        final result = await uploader.prepare(attachment);

        expect(result.description, 'User-provided description');
        expect(result.filename, 'vacation.jpg');
        expect(result.mediaType, 'image/jpeg');
        expect(result.lastModifiedTime, lastModified);
        expect(result.format, AttachmentFormat.hostedMedia.value);
        expect(result.data?.links?.first.toString(), mxcUri);
      });

      test('uses upload result values when caller has none', () async {
        when(
          () => coreSDK.uploadMedia(
            any(),
            senderDid: any(named: 'senderDid'),
            contentType: any(named: 'contentType'),
            filename: any(named: 'filename'),
          ),
        ).thenAnswer(
          (_) async => hostedAttachment(
            filename: 'server-name.jpg',
            mediaType: 'image/png',
            byteCount: 512,
          ),
        );

        final attachment = ChatAttachment(
          data: ChatAttachmentData(base64: '/9j/4AAQSkZJRg=='),
        );

        final result = await uploader.prepare(attachment);

        expect(result.filename, 'server-name.jpg');
        expect(result.mediaType, 'image/png');
        expect(result.byteCount, 512);
      });

      test('caller-provided values take precedence over server', () async {
        when(
          () => coreSDK.uploadMedia(
            any(),
            senderDid: any(named: 'senderDid'),
            contentType: any(named: 'contentType'),
            filename: any(named: 'filename'),
          ),
        ).thenAnswer(
          (_) async => hostedAttachment(
            filename: 'server-assigned.jpg',
            mediaType: 'image/png',
            byteCount: 999,
          ),
        );

        final attachment = ChatAttachment(
          filename: 'user-chosen.jpg',
          mediaType: 'image/jpeg',
          byteCount: 2048,
          data: ChatAttachmentData(base64: '/9j/4AAQSkZJRg=='),
        );

        final result = await uploader.prepare(attachment);

        expect(result.filename, 'user-chosen.jpg');
        expect(result.mediaType, 'image/jpeg');
        expect(result.byteCount, 2048);
      });
    });

    group('prepareAll', () {
      test('returns empty list for empty input', () async {
        final result = await uploader.prepareAll([]);
        expect(result, isEmpty);
      });

      test('processes multiple attachments sequentially', () async {
        var callCount = 0;
        when(
          () => coreSDK.uploadMedia(
            any(),
            senderDid: any(named: 'senderDid'),
            contentType: any(named: 'contentType'),
            filename: any(named: 'filename'),
          ),
        ).thenAnswer((_) async {
          callCount++;
          return hostedAttachment(filename: 'file$callCount.jpg');
        });

        final attachments = [
          ChatAttachment(
            filename: 'a.jpg',
            mediaType: 'image/jpeg',
            data: ChatAttachmentData(base64: '/9j/4AAQSkZJRg=='),
          ),
          ChatAttachment(
            filename: 'b.jpg',
            mediaType: 'image/jpeg',
            data: ChatAttachmentData(base64: '/9j/4AAQSkZJRg=='),
          ),
        ];

        final results = await uploader.prepareAll(attachments);
        expect(results, hasLength(2));
        expect(callCount, 2);
      });
    });
  });
}
