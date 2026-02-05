enum AttachmentFormat {
  contactCard('https://affinidi.io/mpx/core-sdk/attachment/contact-card'),
  imageSelfie('https://affinidi.io/mpx/core-sdk/attachment/image-selfie'),
  verifiablePresentation(
    'https://affinidi.io/mpx/core-sdk/attachment/verifiable-presentation',
  ),
  rCardCredential(
    'https://affinidi.io/mpx/core-sdk/attachment/rcard-credential',
  );

  const AttachmentFormat(this.value);

  final String value;
}
