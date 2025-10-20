enum AttachmentMediaType {
  textVcard('text/x-vcard'),
  imageJpeg('image/jpeg'),
  verifiablePresentation('text/vp-something'),
  verifiableCredential('text/vc-something');

  const AttachmentMediaType(this.value);

  final String value;
}
