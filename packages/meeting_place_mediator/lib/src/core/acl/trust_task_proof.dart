import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:didcomm/didcomm.dart';
import 'package:ssi/ssi.dart';

/// Signs a Trust Task the way a mediator verifies one: an `eddsa-jcs-2022`
/// Data Integrity proof over the document, made with the issuer's
/// authentication key.
///
/// A mediator that enforces Trust Task verification refuses a task whose
/// type requires a proof, such as `messaging/access-list/update`, when it
/// carries none. Written out rather than with the `ssi` generator, which
/// always adds a `nonce`: the proof carries `created` in whole seconds and
/// no `nonce`, as the Trust Task proofs of the VTC SDK do.
abstract final class TrustTaskProof {
  static const _cryptosuite = 'eddsa-jcs-2022';

  /// Returns [document] with a proof made by [signer], whose key the issuer
  /// lists for authentication.
  ///
  /// Only an Ed25519 key can make the proof; with any other, such as the
  /// P-256 key of a DID made before Meeting Place moved to Ed25519,
  /// [document] is returned unsigned, as a mediator that only warns on an
  /// unsigned task still accepts it.
  static Future<TrustTaskDocument> sign(
    TrustTaskDocument document, {
    required DidSigner signer,
    DateTime? created,
  }) async {
    if (signer.signatureScheme != SignatureScheme.ed25519) return document;

    final unsecured = document.toJson()..remove('proof');
    final proofConfig = <String, dynamic>{
      'type': 'DataIntegrityProof',
      'cryptosuite': _cryptosuite,
      'created': _wholeSeconds(created ?? DateTime.now()),
      'verificationMethod': signer.didKeyId,
      'proofPurpose': 'authentication',
    };
    final signature = await signer.sign(hashData(proofConfig, unsecured));

    return TrustTaskDocument(
      id: document.id,
      type: document.type,
      issuer: document.issuer,
      recipient: document.recipient,
      issuedAt: document.issuedAt,
      payload: document.payload,
      threadId: document.threadId,
      proof: {...proofConfig, 'proofValue': toMultiBase(signature)},
    );
  }

  /// What `eddsa-jcs-2022` signs: the SHA-256 of the canonical proof
  /// configuration, then of the canonical document without its proof.
  static Uint8List hashData(
    Map<String, dynamic> proofConfig,
    Map<String, dynamic> unsecured,
  ) => Uint8List.fromList([
    ...sha256.convert(utf8.encode(JcsUtil.canonicalize(proofConfig))).bytes,
    ...sha256.convert(utf8.encode(JcsUtil.canonicalize(unsecured))).bytes,
  ]);

  /// [time] as an RFC 3339 UTC timestamp in whole seconds.
  static String _wholeSeconds(DateTime time) {
    final iso = time.toUtc().toIso8601String();
    return '${iso.substring(0, iso.indexOf('.'))}Z';
  }
}
