/// Exception thrown by Matrix media operations.
class MatrixMediaException implements Exception {
  MatrixMediaException({
    required this.code,
    required this.message,
    this.innerException,
    this.retryAfterMs,
  });

  factory MatrixMediaException.tooLarge({int? maxBytes}) =>
      MatrixMediaException(
        code: codeTooLarge,
        message: maxBytes != null
            ? 'File exceeds maximum upload size of $maxBytes bytes'
            : 'File exceeds maximum upload size',
      );

  factory MatrixMediaException.forbidden(String reason) =>
      MatrixMediaException(code: codeForbidden, message: reason);

  factory MatrixMediaException.notFound(String mediaId) => MatrixMediaException(
    code: codeNotFound,
    message: 'Media not found: $mediaId',
  );

  factory MatrixMediaException.rateLimited({int? retryAfterMs}) =>
      MatrixMediaException(
        code: codeRateLimited,
        message: 'Rate limited by media server',
        retryAfterMs: retryAfterMs,
      );

  factory MatrixMediaException.networkError(Object innerException) =>
      MatrixMediaException(
        code: codeNetworkError,
        message: 'Network error during media operation',
        innerException: innerException,
      );

  factory MatrixMediaException.invalidMediaId(String mediaId) =>
      MatrixMediaException(
        code: codeInvalidMediaId,
        message: 'Invalid media ID characters: $mediaId',
      );

  factory MatrixMediaException.serverError(int statusCode) =>
      MatrixMediaException(
        code: codeServerError,
        message: 'Media server returned status $statusCode',
      );

  factory MatrixMediaException.decryptionFailed() => MatrixMediaException(
    code: codeDecryptionFailed,
    message: 'Ciphertext hash mismatch or decryption failed',
  );

  factory MatrixMediaException.invalidMetadata(String reason) =>
      MatrixMediaException(code: codeInvalidMetadata, message: reason);

  static const codeTooLarge = 'too_large';
  static const codeForbidden = 'forbidden';
  static const codeNotFound = 'not_found';
  static const codeRateLimited = 'rate_limited';
  static const codeNetworkError = 'network_error';
  static const codeInvalidMediaId = 'invalid_media_id';
  static const codeServerError = 'server_error';
  static const codeDecryptionFailed = 'decryption_failed';
  static const codeInvalidMetadata = 'invalid_metadata';

  final String code;
  final String message;
  final Object? innerException;
  final int? retryAfterMs;

  @override
  String toString() => 'MediaException($code): $message';
}
