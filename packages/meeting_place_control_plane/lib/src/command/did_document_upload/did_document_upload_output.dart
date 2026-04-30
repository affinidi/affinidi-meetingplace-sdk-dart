class DidDocumentUploadCommandOutput {
  DidDocumentUploadCommandOutput({
    required this.did,
    this.didDocUrl,
    this.segment,
  });

  final String did;
  final String? didDocUrl;
  final String? segment;
}
