enum AttachmentFormat {
  contactCard('https://affinidi.io/mpx/core-sdk/attachment/contact-card'),
  imageSelfie('https://affinidi.io/mpx/core-sdk/attachment/image-selfie'),
  hostedMedia('https://affinidi.io/mpx/core-sdk/attachment/hosted-media'),
  verifiablePresentation(
    'https://affinidi.io/mpx/core-sdk/attachment/verifiable-presentation',
  );

  const AttachmentFormat(this.value);

  final String value;
}
