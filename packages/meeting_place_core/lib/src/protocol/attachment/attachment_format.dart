/// The kinds of content a DIDComm message attachment can carry.
enum AttachmentFormat {
  /// A contact card shared as an attachment.
  contactCard('https://affinidi.io/mpx/core-sdk/attachment/contact-card'),

  /// A selfie image captured for verification purposes.
  imageSelfie('https://affinidi.io/mpx/core-sdk/attachment/image-selfie'),

  /// A verifiable presentation.
  verifiablePresentation(
    'https://affinidi.io/mpx/core-sdk/attachment/verifiable-presentation',
  );

  const AttachmentFormat(this.value);

  /// The URI identifying this attachment format.
  final String value;
}
