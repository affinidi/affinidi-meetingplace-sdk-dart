enum AttachmentFormat {
  contactCard('https://affinidi.io/mpx/core-sdk/attachment/contact-card'),
  imageSelfie('https://affinidi.io/mpx/core-sdk/attachment/image-selfie'),
  // TODO (earl): remove this once the app is updated. currently app needs this
  // especially to pass melos analyze in precommit hook.
  hostedMedia('https://affinidi.io/mpx/core-sdk/attachment/hosted-media'),
  verifiablePresentation(
    'https://affinidi.io/mpx/core-sdk/attachment/verifiable-presentation',
  );

  const AttachmentFormat(this.value);

  final String value;
}
