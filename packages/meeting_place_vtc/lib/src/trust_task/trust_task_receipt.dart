import 'trust_task_document.dart';

/// What shows that a Trust Task was signed and answered: the request's
/// type, signer and proof, and who answered it, with the proof of the
/// answer, which checked out.
///
/// Holds no payload and no signature: a payload can carry details the
/// member disclosed, so a receipt is safe to keep and to show.
class TrustTaskReceipt {
  /// Creates a [TrustTaskReceipt].
  const TrustTaskReceipt({
    required this.type,
    required this.documentId,
    required this.signer,
    required this.answeredBy,
    this.answerType,
    this.answerDocumentId,
    this.signedAt,
    this.cryptosuite,
    this.verificationMethod,
    this.proofPurpose,
    this.answeredAt,
    this.answerSignedAt,
    this.answerCryptosuite,
    this.answerVerificationMethod,
    this.answerProofPurpose,
  });

  /// The receipt for [request], signed, and [answer], its verified answer.
  factory TrustTaskReceipt.exchange(
    TrustTaskDocument request,
    TrustTaskDocument answer,
  ) {
    final proof = _proofOf(request);
    final answerProof = _proofOf(answer);
    return TrustTaskReceipt(
      type: request.type,
      documentId: request.id,
      signer: request.issuer,
      signedAt: _time(proof['created']),
      cryptosuite: _string(proof['cryptosuite']),
      verificationMethod: _string(proof['verificationMethod']),
      proofPurpose: _string(proof['proofPurpose']),
      answeredBy: answer.issuer,
      answerType: answer.type,
      answerDocumentId: answer.id,
      answeredAt: _time(answer.toJson()['issuedAt']),
      answerSignedAt: _time(answerProof['created']),
      answerCryptosuite: _string(answerProof['cryptosuite']),
      answerVerificationMethod: _string(answerProof['verificationMethod']),
      answerProofPurpose: _string(answerProof['proofPurpose']),
    );
  }

  /// Restores a [TrustTaskReceipt] stored with [toJson]. A receipt stored
  /// before the answer's proof was kept has none.
  factory TrustTaskReceipt.fromJson(Map<String, dynamic> json) {
    return TrustTaskReceipt(
      type: json['type'] as String,
      documentId: json['documentId'] as String,
      signer: json['signer'] as String,
      answeredBy: json['answeredBy'] as String,
      answerType: _string(json['answerType']),
      answerDocumentId: _string(json['answerDocumentId']),
      signedAt: _time(json['signedAt']),
      cryptosuite: _string(json['cryptosuite']),
      verificationMethod: _string(json['verificationMethod']),
      proofPurpose: _string(json['proofPurpose']),
      answeredAt: _time(json['answeredAt']),
      answerSignedAt: _time(json['answerSignedAt']),
      answerCryptosuite: _string(json['answerCryptosuite']),
      answerVerificationMethod: _string(json['answerVerificationMethod']),
      answerProofPurpose: _string(json['answerProofPurpose']),
    );
  }

  /// The request's Trust Task type URI.
  final String type;

  /// The request's document id, a `urn:uuid`.
  final String documentId;

  /// DID that signed the request.
  final String signer;

  /// When the request was signed, as its proof says.
  final DateTime? signedAt;

  /// The proof's cryptosuite, e.g. `eddsa-jcs-2022`.
  final String? cryptosuite;

  /// The key that signed the request, a DID URL.
  final String? verificationMethod;

  /// What the request's proof is for, e.g. `authentication`.
  final String? proofPurpose;

  /// DID that signed the answer, which was verified against its document.
  final String answeredBy;

  /// The answer's Trust Task type URI, e.g. the request's with `#response`.
  final String? answerType;

  /// The answer's document id.
  final String? answerDocumentId;

  /// When the answer was issued, as it says.
  final DateTime? answeredAt;

  /// When the answer was signed, as its proof says.
  final DateTime? answerSignedAt;

  /// The cryptosuite of the answer's proof.
  final String? answerCryptosuite;

  /// The key of [answeredBy] that signed the answer, a DID URL.
  final String? answerVerificationMethod;

  /// What the answer's proof is for, e.g. `authentication`.
  final String? answerProofPurpose;

  /// Serialises for storage.
  Map<String, dynamic> toJson() => {
    'type': type,
    'documentId': documentId,
    'signer': signer,
    'answeredBy': answeredBy,
    'answerType': ?answerType,
    'answerDocumentId': ?answerDocumentId,
    'signedAt': ?signedAt?.toUtc().toIso8601String(),
    'cryptosuite': ?cryptosuite,
    'verificationMethod': ?verificationMethod,
    'proofPurpose': ?proofPurpose,
    'answeredAt': ?answeredAt?.toUtc().toIso8601String(),
    'answerSignedAt': ?answerSignedAt?.toUtc().toIso8601String(),
    'answerCryptosuite': ?answerCryptosuite,
    'answerVerificationMethod': ?answerVerificationMethod,
    'answerProofPurpose': ?answerProofPurpose,
  };

  static Map<dynamic, dynamic> _proofOf(TrustTaskDocument document) =>
      switch (document.toJson()['proof']) {
        final Map<dynamic, dynamic> proof => proof,
        _ => const {},
      };

  static String? _string(Object? value) => value is String ? value : null;

  static DateTime? _time(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}
