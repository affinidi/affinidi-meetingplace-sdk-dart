/// Result of uploading media to the Matrix homeserver.
class MediaUploadResult {
  MediaUploadResult({
    required this.contentUri,
    required this.sizeBytes,
    required this.contentType,
  });

  /// The mxc:// URI returned by the homeserver.
  final String contentUri;

  /// The size of the uploaded content in bytes.
  final int sizeBytes;

  /// The MIME type of the uploaded content.
  final String contentType;
}
