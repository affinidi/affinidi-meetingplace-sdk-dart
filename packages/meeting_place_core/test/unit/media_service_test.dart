import 'dart:convert';
import 'dart:typed_data';

import 'package:meeting_place_core/src/protocol/attachment/attachment_format.dart';
import 'package:meeting_place_core/src/protocol/attachment/attachment_media_utils.dart';
import 'package:meeting_place_core/src/service/matrix/matrix_service.dart';
import 'package:meeting_place_core/src/service/matrix/media/encrypted_file_info.dart';
import 'package:meeting_place_core/src/service/matrix/media/media_exception.dart';
import 'package:meeting_place_core/src/service/matrix/media/media_service.dart';
import 'package:meeting_place_core/src/service/matrix/media/media_upload_result.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

class MockMatrixService extends Mock implements MatrixService {}

class MockDidManager extends Mock implements DidManager {}

const _mxcUri = 'mxc://matrix.example.com/media123';

EncryptedFileInfo _stubEncryptedFileInfo({String url = _mxcUri}) {
  return EncryptedFileInfo(
    url: url,
    key: JsonWebKey(k: base64Url.encode(Uint8List(32)).replaceAll('=', '')),
    iv: base64.encode(Uint8List(16)).replaceAll('=', ''),
    hashes: {
      encryptedFileSha256Key: base64.encode(Uint8List(32)).replaceAll('=', ''),
    },
  );
}

void main() {
  late MockMatrixService matrixService;
  late MockDidManager didManager;
  late MediaService mediaService;

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(MockDidManager());
  });

  setUp(() {
    matrixService = MockMatrixService();
    didManager = MockDidManager();
    mediaService = MediaService(matrixService: matrixService);
  });

  test('upload rejects files over the homeserver limit', () async {
    when(
      () => matrixService.getMediaConfig(didManager: didManager),
    ).thenAnswer((_) async => 16);

    await expectLater(
      () => mediaService.upload(
        Uint8List(32),
        didManager: didManager,
        contentType: 'image/png',
      ),
      throwsA(
        isA<MediaException>().having(
          (error) => error.code,
          'code',
          MediaException.codeTooLarge,
        ),
      ),
    );

    verifyNever(
      () => matrixService.uploadMedia(
        any(),
        didManager: any(named: 'didManager'),
        contentType: any(named: 'contentType'),
        filename: any(named: 'filename'),
      ),
    );
  });

  test('download rejects mismatched encrypted metadata', () async {
    await expectLater(
      () => mediaService.download(
        'mxc://matrix.example.com/other-media',
        didManager: didManager,
        encryptedFileInfo: _stubEncryptedFileInfo(),
      ),
      throwsA(
        isA<MediaException>().having(
          (error) => error.code,
          'code',
          MediaException.codeInvalidMediaId,
        ),
      ),
    );

    verifyNever(
      () => matrixService.downloadMedia(any(), didManager: didManager),
    );
  });

  test('download rejects invalid mxc URIs', () async {
    await expectLater(
      () => mediaService.download(
        'not-a-valid-uri',
        didManager: didManager,
        encryptedFileInfo: _stubEncryptedFileInfo(url: 'not-a-valid-uri'),
      ),
      throwsA(
        isA<MediaException>().having(
          (error) => error.code,
          'code',
          MediaException.codeInvalidMediaId,
        ),
      ),
    );
  });

  test('attachmentFromMediaUpload preserves hosted-media metadata', () {
    final encryptedFileInfo = _stubEncryptedFileInfo();
    final uploadOutput = MediaUploadOutput(
      result: MediaUploadResult(
        contentUri: _mxcUri,
        sizeBytes: 128,
        contentType: 'image/png',
      ),
      encryptedFileInfo: encryptedFileInfo,
    );

    final attachment = attachmentFromMediaUpload(
      uploadOutput,
      mediaType: 'image/png',
      filename: 'image.png',
      description: 'Hosted image',
    );

    expect(isHostedMediaAttachment(attachment), isTrue);
    expect(getMxcUri(attachment), _mxcUri);
    expect(attachment.format, AttachmentFormat.hostedMedia.value);
    expect(attachment.filename, 'image.png');

    final parsed = getEncryptedFileInfo(attachment);
    expect(parsed, isNotNull);
    expect(parsed!.url, encryptedFileInfo.url);
    expect(
      parsed.hashes[encryptedFileSha256Key],
      encryptedFileInfo.hashes[encryptedFileSha256Key],
    );
  });
}
