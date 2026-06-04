import 'dart:typed_data';

import 'package:matrix/matrix.dart' as matrix;
import 'package:ssi/ssi.dart';

import '../../../loggers/default_meeting_place_core_sdk_logger.dart';
import '../../../loggers/meeting_place_core_sdk_logger.dart';
import '../matrix_service.dart';
import 'encrypted_file_info.dart';
import 'matrix_media_uri.dart';
import 'media_exception.dart';
import 'media_upload_result.dart';

const _encryptedUploadContentType = 'application/octet-stream';

/// Orchestrates encrypted media upload and download against the Matrix
/// homeserver.
///
/// Encryption and decryption are delegated to `package:matrix`'s
/// [matrix.encryptFile] / [matrix.decryptFileImplementation], which implement
/// the Matrix v2 encrypted attachment format (AES-CTR-256 + SHA-256). The
/// decryption key and IV are returned as [EncryptedFileInfo] and must be
/// transmitted to the recipient through a secure channel (DIDComm authcrypt).
///
/// Upload flow:
/// 1. Check file size against server limit.
/// 2. Encrypt plaintext via [matrix.encryptFile].
/// 3. Upload ciphertext to Matrix homeserver and obtain an mxc:// URI.
/// 4. Return mxc:// URI and encryption metadata.
///
/// Download flow:
/// 1. Download ciphertext from mxc:// URI.
/// 2. Decrypt via [matrix.decryptFileImplementation], which verifies the
///    SHA-256 hash of the ciphertext before returning plaintext.
class MediaService {
  MediaService({
    required MatrixService matrixService,
    MeetingPlaceCoreSDKLogger? logger,
  }) : _matrixService = matrixService,
       _logger =
           logger ??
           DefaultMeetingPlaceCoreSDKLogger(className: 'MediaService');

  final MatrixService _matrixService;
  final MeetingPlaceCoreSDKLogger _logger;

  /// Encrypts and uploads media to the Matrix homeserver.
  ///
  /// Returns the upload result and the encryption metadata required to
  /// decrypt the ciphertext later.
  ///
  /// Throws [MediaException] on failure.
  Future<MediaUploadOutput> upload(
    Uint8List fileBytes, {
    required DidManager didManager,
    required String contentType,
    String? filename,
  }) async {
    _logger.debug(
      'Uploading media: ${fileBytes.length} bytes, type=$contentType',
      name: 'MediaService',
    );

    final maxSize = await _matrixService.getMediaConfig(didManager: didManager);
    if (maxSize != null && fileBytes.length > maxSize) {
      throw MediaException.tooLarge(maxBytes: maxSize);
    }

    final encryptedFile = await matrix.encryptFile(fileBytes);
    _logger.debug(
      'Encrypted media: ${encryptedFile.data.length} bytes',
      name: 'MediaService',
    );

    final mxcUri = await _matrixService.uploadMedia(
      encryptedFile.data,
      didManager: didManager,
      contentType: _encryptedUploadContentType,
      filename: filename,
    );

    _logger.info('Upload complete', name: 'MediaService');

    return MediaUploadOutput(
      result: MediaUploadResult(
        contentUri: mxcUri.toString(),
        sizeBytes: encryptedFile.data.length,
        contentType: contentType,
      ),
      encryptedFileInfo: _toEncryptedFileInfo(encryptedFile, mxcUri.toString()),
    );
  }

  /// Downloads and decrypts media from the Matrix homeserver.
  ///
  /// [encryptedFileInfo] must reference the same mxc:// URI as [mxcUri] and
  /// carry the AES-CTR key, IV, and SHA-256 hash produced by [upload].
  ///
  /// Throws [MediaException] on network/server errors, on URI/metadata
  /// mismatch, or with code [MediaException.codeDecryptionFailed] when hash
  /// verification or decryption fails.
  Future<Uint8List> download(
    String mxcUri, {
    required DidManager didManager,
    required EncryptedFileInfo encryptedFileInfo,
  }) async {
    _logger.debug('Downloading media', name: 'MediaService');

    if (encryptedFileInfo.url != mxcUri) {
      throw MediaException(
        code: MediaException.codeInvalidMediaId,
        message: 'Media URI does not match encryption metadata',
      );
    }

    try {
      parseMatrixMediaUri(mxcUri);
    } on FormatException {
      throw MediaException(
        code: MediaException.codeInvalidMediaId,
        message: 'Invalid media URI',
      );
    }

    final bytes = await _matrixService.downloadMedia(
      mxcUri,
      didManager: didManager,
    );

    final plaintext = await matrix.decryptFileImplementation(
      _toMatrixEncryptedFile(encryptedFileInfo, bytes),
    );
    if (plaintext == null) {
      throw MediaException.decryptionFailed();
    }
    return plaintext;
  }
}

EncryptedFileInfo _toEncryptedFileInfo(
  matrix.EncryptedFile file,
  String mxcUrl,
) {
  return EncryptedFileInfo(
    url: mxcUrl,
    key: JsonWebKey(k: file.k),
    iv: file.iv,
    hashes: {encryptedFileSha256Key: file.sha256},
  );
}

matrix.EncryptedFile _toMatrixEncryptedFile(
  EncryptedFileInfo info,
  Uint8List ciphertext,
) {
  final sha256 = info.hashes[encryptedFileSha256Key];
  if (sha256 == null) {
    throw MediaException.invalidMetadata(
      'Missing sha256 hash in encryption metadata',
    );
  }
  return matrix.EncryptedFile(
    data: ciphertext,
    k: info.key.k,
    iv: info.iv,
    sha256: sha256,
  );
}

/// Combined output of a media upload operation.
class MediaUploadOutput {
  MediaUploadOutput({required this.result, required this.encryptedFileInfo});

  /// The upload result with mxc:// URI.
  final MediaUploadResult result;

  /// Encryption metadata produced by [MediaService.upload]. Must be
  /// transmitted to the recipient through an encrypted channel.
  final EncryptedFileInfo encryptedFileInfo;
}
