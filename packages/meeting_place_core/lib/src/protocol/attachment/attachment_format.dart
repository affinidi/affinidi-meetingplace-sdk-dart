// TODO: apply same structure as protocol messages
enum AttachmentFormat {
  contactCard('https://affinidi.io/mpx/core-sdk/attachment/contact-card'),
  imageSelfie('https://affinidi.io/mpx/core-sdk/attachment/image-selfie'),
  seqNo('https://affinidi.io/mpx/core-sdk/attachment/sequence-no'),
  verifiablePresentation(
    'https://affinidi.io/mpx/core-sdk/attachment/verifiable-presentation',
  ),
  rCardCredential(
    'https://affinidi.io/mpx/core-sdk/attachment/rcard-credential',
  );

  const AttachmentFormat(this.value);

  final String value;
}
