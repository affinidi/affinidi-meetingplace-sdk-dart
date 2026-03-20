enum AttachmentMediaType {
  textContactCard('application/json'),
  imageJpeg('image/jpeg'),
  imagePng('image/png'),
  imageGif('image/gif'),
  imageWebp('image/webp'),
  videoMp4('video/mp4'),
  videoWebm('video/webm'),
  audioMp3('audio/mpeg'),
  audioOgg('audio/ogg'),
  audioWebm('audio/webm'),
  applicationPdf('application/pdf'),
  applicationOctetStream('application/octet-stream'),
  verifiablePresentation('text/vp-something'),
  verifiableCredential('text/vc-something');

  const AttachmentMediaType(this.value);

  final String value;
}
