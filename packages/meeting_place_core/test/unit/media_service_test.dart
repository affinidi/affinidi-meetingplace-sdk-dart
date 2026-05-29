import 'dart:typed_data';

import 'package:meeting_place_core/src/protocol/attachment/attachment_format.dart';
import 'package:meeting_place_core/src/protocol/attachment/attachment_media_utils.dart';
import 'package:meeting_place_core/src/service/matrix/matrix_service.dart';
import 'package:meeting_place_core/src/service/media/media_exception.dart';
import 'package:meeting_place_core/src/service/media/media_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

class MockMatrixService extends Mock implements MatrixService {}

class MockDidManager extends Mock implements DidManager {}

void main() {
  late MockMatrixService matrixService;
  late MockDidManager didManager;
  late MediaService mediaService;

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    matrixService = MockMatrixService();
    didManager = MockDidManager();
    mediaService = MediaService(matrixService: matrixService);
  });

  test('upload encrypts bytes and returns hosted-media metadata', () async {
    final plaintext = Uint8List.fromList([1, 2, 3, 4, 5]);
    late Uint8List uploadedCiphertext;

    when(
      () => matrixService.getMediaConfig(didManager: didManager),
    ).thenAnswer((_) async => 1024);
    when(
      () => matrixService.uploadMedia(
        any(),
        didManager: didManager,
        contentType: 'application/octet-stream',
        filename: 'photo.jpg',
      ),
    ).thenAnswer((invocation) async {
      uploadedCiphertext = invocation.positionalArguments.first as Uint8List;
      return Uri.parse('mxc://matrix.example.com/media123');
    });

    final output = await mediaService.upload(
      plaintext,
      didManager: didManager,
      contentType: 'image/jpeg',
      filename: 'photo.jpg',
    );

    expect(uploadedCiphertext, isNot(equals(plaintext)));
    expect(output.result.contentUri, 'mxc://matrix.example.com/media123');
    expect(output.result.contentType, 'image/jpeg');
    expect(output.encryptedFileInfo, isNotNull);
    expect(output.encryptedFileInfo!.url, output.result.contentUri);
    expect(output.encryptedFileInfo!.hashes['sha256'], isNotEmpty);
  });

  test('download decrypts encrypted media successfully', () async {
    final plaintext = Uint8List.fromList([9, 8, 7, 6]);
    late Uint8List uploadedCiphertext;

    when(
      () => matrixService.getMediaConfig(didManager: didManager),
    ).thenAnswer((_) async => 1024);
    when(
      () => matrixService.uploadMedia(
        any(),
        didManager: didManager,
        contentType: 'application/octet-stream',
        filename: 'secret.bin',
      ),
    ).thenAnswer((invocation) async {
      uploadedCiphertext = invocation.positionalArguments.first as Uint8List;
      return Uri.parse('mxc://matrix.example.com/media999');
    });

    final uploadOutput = await mediaService.upload(
      plaintext,
      didManager: didManager,
      contentType: 'application/octet-stream',
      filename: 'secret.bin',
    );

    when(
      () => matrixService.downloadMedia(
        'mxc://matrix.example.com/media999',
        didManager: didManager,
        roomId: '!room:matrix.example.com',
      ),
    ).thenAnswer((_) async => uploadedCiphertext);

    final downloaded = await mediaService.download(
      uploadOutput.result.contentUri,
      didManager: didManager,
      roomId: '!room:matrix.example.com',
      encryptedFileInfo: uploadOutput.encryptedFileInfo,
    );

    expect(downloaded, plaintext);
  });

  test('download rejects mismatched encrypted metadata', () async {
    final plaintext = Uint8List.fromList([4, 3, 2, 1]);

    when(
      () => matrixService.getMediaConfig(didManager: didManager),
    ).thenAnswer((_) async => 1024);
    when(
      () => matrixService.uploadMedia(
        any(),
        didManager: didManager,
        contentType: 'application/octet-stream',
        filename: null,
      ),
    ).thenAnswer((_) async => Uri.parse('mxc://matrix.example.com/media123'));

    final uploadOutput = await mediaService.upload(
      plaintext,
      didManager: didManager,
      contentType: 'image/png',
    );

    await expectLater(
      () => mediaService.download(
        'mxc://matrix.example.com/other-media',
        didManager: didManager,
        roomId: '!room:matrix.example.com',
        encryptedFileInfo: uploadOutput.encryptedFileInfo,
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

  test('attachment helpers preserve hosted-media metadata', () async {
    final plaintext = Uint8List.fromList([7, 7, 7, 7]);

    when(
      () => matrixService.getMediaConfig(didManager: didManager),
    ).thenAnswer((_) async => 1024);
    when(
      () => matrixService.uploadMedia(
        any(),
        didManager: didManager,
        contentType: 'application/octet-stream',
        filename: 'image.png',
      ),
    ).thenAnswer((_) async => Uri.parse('mxc://matrix.example.com/attachment'));

    final uploadOutput = await mediaService.upload(
      plaintext,
      didManager: didManager,
      contentType: 'image/png',
      filename: 'image.png',
    );

    final attachment = attachmentFromMediaUpload(
      uploadOutput,
      mediaType: 'image/png',
      filename: 'image.png',
      description: 'Hosted image',
    );

    expect(isHostedMediaAttachment(attachment), isTrue);
    expect(getMxcUri(attachment), 'mxc://matrix.example.com/attachment');

    final encryptedFileInfo = getEncryptedFileInfo(attachment);
    expect(encryptedFileInfo, isNotNull);
    expect(
      encryptedFileInfo!.hashes['sha256'],
      uploadOutput.encryptedFileInfo!.hashes['sha256'],
    );
    expect(attachment.format, AttachmentFormat.hostedMedia.value);
    expect(attachment.filename, 'image.png');
  });
}
