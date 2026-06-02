/// Exception thrown by media service operations.
class MediaException implements Exception {
  MediaException({
    required this.code,
    required this.message,
    this.innerException,
    this.retryAfterMs,
  });

  factory MediaException.tooLarge({int? maxBytes}) => MediaException(
    code: codeTooLarge,
    message: maxBytes != null
        ? 'File exceeds maximum upload size of $maxBytes bytes'
        : 'File exceeds maximum upload size',
  );

  factory MediaException.forbidden(String reason) =>
      MediaException(code: codeForbidden, message: reason);

  factory MediaException.notFound(String mediaId) =>
      MediaException(code: codeNotFound, message: 'Media not found: $mediaId');

  factory MediaException.rateLimited({int? retryAfterMs}) => MediaException(
    code: codeRateLimited,
    message: 'Rate limited by media server',
    retryAfterMs: retryAfterMs,
  );

  factory MediaException.networkError(Object innerException) => MediaException(
    code: codeNetworkError,
    message: 'Network error during media operation',
    innerException: innerException,
  );

  factory MediaException.invalidMediaId(String mediaId) => MediaException(
    code: codeInvalidMediaId,
    message: 'Invalid media ID characters: $mediaId',
  );

  factory MediaException.serverError(int statusCode) => MediaException(
    code: codeServerError,
    message: 'Media server returned status $statusCode',
  );
  static const codeTooLarge = 'too_large';
  static const codeForbidden = 'forbidden';
  static const codeNotFound = 'not_found';
  static const codeRateLimited = 'rate_limited';
  static const codeNetworkError = 'network_error';
  static const codeInvalidMediaId = 'invalid_media_id';
  static const codeServerError = 'server_error';

  final String code;
  final String message;
  final Object? innerException;
  final int? retryAfterMs;

  @override
  String toString() => 'MediaException($code): $message';
}
