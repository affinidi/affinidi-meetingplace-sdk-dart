class DidDocumentUploadException implements Exception {
  DidDocumentUploadException.generic({
    required this.message,
    this.innerException,
  });

  final String message;
  final Object? innerException;

  @override
  String toString() => 'DidDocumentUploadException: $message';
}
