/// Parameters for `MeetingPlaceCredentialsSDK.storeVrc`.
class StoreVrcRequest {
  const StoreVrcRequest({
    required this.vcBlob,
    required this.referenceId,
    this.verifiedAt,
    this.receivedAt,
    this.credentialFormat,
  });

  /// The raw serialised VC JSON string to parse and store.
  final String vcBlob;

  /// Identifier used to correlate this VRC with its originating channel or
  /// exchange.
  final String referenceId;

  /// When the VRC was verified. Defaults to the parser's own timestamp when
  /// not provided.
  final DateTime? verifiedAt;

  /// When the VRC was received. Defaults to the parser's own timestamp when
  /// not provided.
  final DateTime? receivedAt;

  /// The credential format the VRC was received in.
  final String? credentialFormat;
}
