/// Response returned after uploading a did:web DID Document
/// on the Control Plane API.
///
/// The [didDocUrl] is the public URL at which the DID Document can be resolved
/// via standard did:web resolution semantics.
class DidDocumentHostingRecord {
  /// Creates a new instance of [DidDocumentHostingRecord].
  DidDocumentHostingRecord({
    required this.did,
    required this.segment,
    required this.didDocUrl,
  });

  /// Creates a [DidDocumentHostingRecord] from the given JSON [json].
  ///
  /// Throws [FormatException] if any required field is absent or not a string.
  factory DidDocumentHostingRecord.fromJson(Map<String, dynamic> json) {
    final did = json['did'];
    final segment = json['segment'];
    final didDocUrl = json['didDocUrl'];
    if (did is! String || segment is! String || didDocUrl is! String) {
      throw const FormatException(
        'DidDocumentHostingRecord: missing or invalid fields in response.',
      );
    }
    return DidDocumentHostingRecord(
      did: did,
      segment: segment,
      didDocUrl: didDocUrl,
    );
  }

  /// The full did:web DID, e.g. `did:web:host:user:alice`.
  final String did;

  /// The last segment of the DID, used in the resolution URL path.
  final String segment;

  /// The public URL at which the DID Document is hosted.
  final String didDocUrl;

  Map<String, dynamic> toJson() {
    return {'did': did, 'segment': segment, 'didDocUrl': didDocUrl};
  }
}
