/// The MIME media types a DIDComm message attachment can carry.
enum AttachmentMediaType {
  /// A contact card, serialized as JSON.
  textContactCard('application/json'),

  /// A JPEG image.
  imageJpeg('image/jpeg'),

  /// A PNG image.
  imagePng('image/png'),

  /// A GIF image.
  imageGif('image/gif'),

  /// A WebP image.
  imageWebp('image/webp'),

  /// An MP4 video.
  videoMp4('video/mp4'),

  /// A QuickTime video.
  videoQuicktime('video/quicktime'),

  /// A WebM video.
  videoWebm('video/webm'),

  /// An MP4 audio track.
  audioMp4('audio/mp4'),

  /// An MPEG audio track.
  audioMpeg('audio/mpeg'),

  /// An Ogg audio track.
  audioOgg('audio/ogg'),

  /// A WAV audio track.
  audioWav('audio/wav'),

  /// A PDF document.
  applicationPdf('application/pdf'),

  /// Arbitrary binary data.
  applicationOctetStream('application/octet-stream'),

  /// A verifiable presentation.
  verifiablePresentation('text/vp-something'),

  /// A verifiable credential.
  verifiableCredential('text/vc-something');

  const AttachmentMediaType(this.value);

  /// The MIME type string identifying this media type.
  final String value;
}
