/// A compact JWS proof with an embedded payload as required by the did:web DID
/// Document upload flow.
///
/// Both `controlProof` (signed by the `controlDid` key) and `proof` (signed by
/// the new `#auth` key in the DID Document) share this structure.
class DidWebProof {
  /// Creates a new instance of [DidWebProof].
  ///
  /// **Parameters:**
  /// - [type]: The proof type. Expected value: `JsonWebSignature2020`.
  /// - [created]: ISO-8601 UTC timestamp of when the proof was created.
  /// - [verificationMethod]: Key identifier used to sign the proof,
  /// e.g. `did:web:<host>:user:<segment>#auth`.
  /// - [proofPurpose]: The intended purpose. Expected value: `authentication`.
  /// - [jws]: Compact JWS with an embedded payload over the canonical proof
  ///   payload (base64url, no padding).
  DidWebProof({
    required this.type,
    required this.created,
    required this.verificationMethod,
    required this.proofPurpose,
    required this.jws,
  });

  /// Creates a [DidWebProof] from the given JSON [json].
  ///
  /// Throws [FormatException] if any required field is absent or not a string.
  factory DidWebProof.fromJson(Map<String, dynamic> json) {
    final type = json['type'];
    final created = json['created'];
    final verificationMethod = json['verificationMethod'];
    final proofPurpose = json['proofPurpose'];
    final jws = json['jws'];
    if (type is! String ||
        created is! String ||
        verificationMethod is! String ||
        proofPurpose is! String ||
        jws is! String) {
      throw const FormatException(
        'DidWebProof: missing or invalid fields in JSON.',
      );
    }
    if (DateTime.tryParse(created) == null) {
      throw const FormatException(
        'DidWebProof: "created" must be a valid ISO-8601 datetime string.',
      );
    }
    return DidWebProof(
      type: type,
      created: created,
      verificationMethod: verificationMethod,
      proofPurpose: proofPurpose,
      jws: jws,
    );
  }

  /// The proof type. Expected value: `JsonWebSignature2020`.
  final String type;

  /// ISO-8601 UTC timestamp of when the proof was created.
  final String created;

  /// Key identifier used to sign the proof,
  /// e.g. `did:web:<host>:user:<segment>#auth`.
  final String verificationMethod;

  /// The intended proof purpose. Expected value: `authentication`.
  final String proofPurpose;

  /// Compact JWS with an embedded payload over the canonical proof payload
  /// (base64url, no padding).
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
