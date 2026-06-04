import 'dart:typed_data';

import 'package:ssi/ssi.dart';

import '../../../loggers/default_meeting_place_core_sdk_logger.dart';
import '../../../loggers/meeting_place_core_sdk_logger.dart';
import '../matrix_service.dart';
import 'encrypted_file_info.dart';
import 'matrix_media_uri.dart';
import 'media_encryption_service.dart';
import 'media_exception.dart';
import 'media_upload_result.dart';

const _encryptedUploadContentType = 'application/octet-stream';

/// Orchestrates media upload and download with optional client-side encryption.
///
/// When [encryptionEnabled] is true (the default), files are encrypted with
/// AES-CTR-256 before upload so the homeserver never sees plaintext content.
/// The decryption key and IV are returned as [EncryptedFileInfo] and must be
/// transmitted to the recipient through a secure channel (DIDComm authcrypt).
///
/// Upload flow:
/// 1. Check file size against server limit
/// 2. Encrypt plaintext → ciphertext (AES-CTR-256)
/// 3. Upload ciphertext to Matrix homeserver → mxc:// URI
/// 4. Return mxc:// URI + encryption metadata
///
/// Download flow:
/// 1. Download ciphertext from mxc:// URI
/// 2. Verify SHA-256 hash of ciphertext
/// 3. Decrypt ciphertext → plaintext
/// 4. Return plaintext bytes
class MediaService {
  MediaService({
    required MatrixService matrixService,
    MeetingPlaceCoreSDKLogger? logger,
    MediaEncryptionService? encryptionService,
    this.encryptionEnabled = true,
  }) : _matrixService = matrixService,
       _logger =
           logger ??
           DefaultMeetingPlaceCoreSDKLogger(className: 'MediaService'),
       _encryptionService = encryptionService ?? MediaEncryptionService();

  final MatrixService _matrixService;
  final MeetingPlaceCoreSDKLogger _logger;
  final MediaEncryptionService _encryptionService;
  final bool encryptionEnabled;

  /// Uploads media to the Matrix homeserver.
  ///
  /// If [encryptionEnabled] is true, encrypts the file before upload.
  /// Returns the upload result with optional encryption metadata.
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

    Uint8List uploadBytes;
    EncryptionResult? encryptionResult;

    if (encryptionEnabled) {
      encryptionResult = _encryptionService.encrypt(fileBytes);
      uploadBytes = encryptionResult.ciphertext;
      _logger.debug(
        'Encrypted media: ${uploadBytes.length} bytes',
        name: 'MediaService',
      );
    } else {
      uploadBytes = fileBytes;
    }

    final mxcUri = await _matrixService.uploadMedia(
      uploadBytes,
      didManager: didManager,
      contentType: encryptionEnabled
          ? _encryptedUploadContentType
          : contentType,
      filename: filename,
    );

    final uploadResult = MediaUploadResult(
      contentUri: mxcUri.toString(),
      sizeBytes: uploadBytes.length,
      contentType: contentType,
    );

    EncryptedFileInfo? encryptedFileInfo;
    if (encryptionResult != null) {
      encryptedFileInfo = encryptionResult.toEncryptedFileInfo(
        mxcUri.toString(),
      );
    }

    _logger.info('Upload complete', name: 'MediaService');

    return MediaUploadOutput(
      result: uploadResult,
      encryptedFileInfo: encryptedFileInfo,
    );
  }

  /// Downloads media from the Matrix homeserver.
  ///
  /// If [encryptedFileInfo] is provided, verifies the hash and decrypts
  /// the downloaded ciphertext.
  ///
  /// Throws [MediaException] on network/server errors.
  /// Throws [MediaDecryptionException] if hash verification fails.
  Future<Uint8List> download(
    String mxcUri, {
    required DidManager didManager,
    EncryptedFileInfo? encryptedFileInfo,
  }) async {
    _logger.debug('Downloading media', name: 'MediaService');

    if (encryptedFileInfo != null && encryptedFileInfo.url != mxcUri) {
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

    if (encryptedFileInfo != null) {
      return _encryptionService.decrypt(bytes, encryptedFileInfo);
    }

    return bytes;
  }
}

/// Combined output of a media upload operation.
class MediaUploadOutput {
  MediaUploadOutput({required this.result, this.encryptedFileInfo});

  /// The upload result with mxc:// URI.
  final MediaUploadResult result;

  /// Encryption metadata, present when E2EE was applied.
  /// Must be transmitted to the recipient through an encrypted channel.
  final EncryptedFileInfo? encryptedFileInfo;
}
