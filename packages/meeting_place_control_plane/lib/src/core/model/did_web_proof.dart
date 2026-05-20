/// A detached JWS proof as required by the did:web DID Document upload flow.
///
/// Both `controlProof` (signed by the `controlDid` key) and `proof` (signed by
/// the new `#auth` key in the DID Document) share this structure.
/// See the MPX Matrix Integration ADR for the canonical proof payload spec.
class DidWebProof {
  DidWebProof({
    required this.type,
    required this.created,
    required this.verificationMethod,
    required this.proofPurpose,
    required this.jws,
  });

  factory DidWebProof.fromJson(Map<String, dynamic> json) {
    return DidWebProof(
      type: json['type'] as String,
      created: json['created'] as String,
      verificationMethod: json['verificationMethod'] as String,
      proofPurpose: json['proofPurpose'] as String,
      jws: json['jws'] as String,
    );
  }

  final String type;

  /// ISO 8601 timestamp.
  final String created;

  /// Key identifier, e.g. `did:web:<host>:user:<segment>#auth`.
  final String verificationMethod;

  final String proofPurpose;

  /// Detached JWS over the canonical proof payload (base64url, no padding).
  final String jws;

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'created': created,
      'verificationMethod': verificationMethod,
      'proofPurpose': proofPurpose,
      'jws': jws,
    };
  }
}
