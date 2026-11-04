import 'trust_task_document.dart';

/// What shows that a Trust Task was signed and answered: the request's
/// type, signer and proof, and who answered it, whose proof checked out.
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
    this.signedAt,
    this.cryptosuite,
    this.verificationMethod,
    this.answeredAt,
  });

  /// The receipt for [request], signed, and [answer], its verified answer.
  factory TrustTaskReceipt.exchange(
    TrustTaskDocument request,
    TrustTaskDocument answer,
  ) {
    final proof = request.toJson()['proof'];
    final proofOf = proof is Map ? proof : const <String, dynamic>{};
    return TrustTaskReceipt(
      type: request.type,
      documentId: request.id,
      signer: request.issuer,
      signedAt: _time(proofOf['created']),
      cryptosuite: _string(proofOf['cryptosuite']),
      verificationMethod: _string(proofOf['verificationMethod']),
      answeredBy: answer.issuer,
      answeredAt: _time(answer.toJson()['issuedAt']),
    );
  }

  /// Restores a [TrustTaskReceipt] stored with [toJson].
  factory TrustTaskReceipt.fromJson(Map<String, dynamic> json) {
    return TrustTaskReceipt(
      type: json['type'] as String,
      documentId: json['documentId'] as String,
      signer: json['signer'] as String,
      answeredBy: json['answeredBy'] as String,
      signedAt: _time(json['signedAt']),
      cryptosuite: _string(json['cryptosuite']),
      verificationMethod: _string(json['verificationMethod']),
      answeredAt: _time(json['answeredAt']),
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

  /// DID that signed the answer, which was verified against its document.
  final String answeredBy;

  /// When the answer was issued, as it says.
  final DateTime? answeredAt;

  /// Serialises for storage.
  Map<String, dynamic> toJson() => {
    'type': type,
    'documentId': documentId,
    'signer': signer,
    'answeredBy': answeredBy,
    'signedAt': ?signedAt?.toUtc().toIso8601String(),
    'cryptosuite': ?cryptosuite,
    'verificationMethod': ?verificationMethod,
    'answeredAt': ?answeredAt?.toUtc().toIso8601String(),
  };

  static String? _string(Object? value) => value is String ? value : null;

  static DateTime? _time(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}
