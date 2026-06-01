/// Categorizes media content types into broad categories for rendering
/// decisions.
///
/// Used by consuming apps to determine how to display a hosted media
/// attachment (e.g., show an image viewer, a video player, or a file icon).
enum MediaCategory {
  /// Image content (image/jpeg, image/png, image/gif, image/webp, etc.)
  image,

  /// Video content (video/mp4, video/quicktime, video/webm, etc.)
  video,

  /// Audio content (audio/mpeg, audio/ogg, audio/wav, etc.)
  audio,

  /// Document or generic file (application/pdf, text/plain, etc.)
  document,
}

/// Determines the [MediaCategory] from a MIME content type string.
///
/// Returns [MediaCategory.document] for unrecognized or null types.
MediaCategory mediaCategoryFromContentType(String? contentType) {
  if (contentType == null || contentType.isEmpty) return MediaCategory.document;
  if (contentType.startsWith('image/')) return MediaCategory.image;
  if (contentType.startsWith('video/')) return MediaCategory.video;
  if (contentType.startsWith('audio/')) return MediaCategory.audio;
  return MediaCategory.document;
}
