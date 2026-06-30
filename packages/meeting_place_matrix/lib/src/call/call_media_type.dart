/// Whether a call carries video or is audio-only.
enum CallMediaType {
  /// Both audio and video tracks are published.
  video,

  /// Only audio is published; the camera is not activated.
  audio,
}
