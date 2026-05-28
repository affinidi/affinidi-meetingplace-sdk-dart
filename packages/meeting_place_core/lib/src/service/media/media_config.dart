/// Configuration for the media repository, obtained from the homeserver.
class MediaConfig {
  MediaConfig({required this.maxUploadSize});

  /// Maximum upload size in bytes. Null means no server-reported limit.
  final int? maxUploadSize;
}
