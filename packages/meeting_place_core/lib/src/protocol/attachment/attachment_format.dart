enum AttachmentFormat {
  contactCard('https://affinidi.io/mpx/core-sdk/attachment/contact-card'),
  imageSelfie('https://affinidi.io/mpx/core-sdk/attachment/image-selfie'),
  verifiablePresentation(
    'https://affinidi.io/mpx/core-sdk/attachment/verifiable-presentation',
  ),
  matrixMedia('https://affinidi.io/mpx/core-sdk/attachment/matrix-media'),
  matrixImage('https://affinidi.io/mpx/core-sdk/attachment/matrix-image'),
  matrixVideo('https://affinidi.io/mpx/core-sdk/attachment/matrix-video'),
  matrixAudio('https://affinidi.io/mpx/core-sdk/attachment/matrix-audio'),
  matrixFile('https://affinidi.io/mpx/core-sdk/attachment/matrix-file');

  const AttachmentFormat(this.value);

  final String value;
}
