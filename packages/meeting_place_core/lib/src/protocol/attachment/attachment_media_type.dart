enum AttachmentMediaType {
  textContactCard('application/json'),
  imageJpeg('image/jpeg'),
  imagePng('image/png'),
  imageGif('image/gif'),
  imageWebp('image/webp'),
  videoMp4('video/mp4'),
  videoQuicktime('video/quicktime'),
  videoWebm('video/webm'),
  audioMpeg('audio/mpeg'),
  audioOgg('audio/ogg'),
  applicationPdf('application/pdf'),
  applicationOctetStream('application/octet-stream'),
  verifiablePresentation('text/vp-something'),
  verifiableCredential('text/vc-something');

  const AttachmentMediaType(this.value);

  final String value;
}
