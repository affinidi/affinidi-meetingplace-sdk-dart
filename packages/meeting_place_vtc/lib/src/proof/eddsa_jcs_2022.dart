import 'dart:convert';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:ssi/ssi.dart';

import '../meeting_place_vtc_sdk_exception.dart';
import '../trust_task/trust_task_time.dart';
import 'trust_task_signer.dart';

/// Signs and verifies documents with the `eddsa-jcs-2022` Data Integrity
/// cryptosuite.
///
/// Implemented here rather than with the `ssi` generator because Trust Task
/// proofs must match the wire format exactly: `created` in whole seconds and
/// no `nonce`, which the `ssi` generator always adds.
abstract final class EddsaJcs2022 {
  static const _proofType = 'DataIntegrityProof';
  static const _cryptosuite = 'eddsa-jcs-2022';
  static const _ed25519MulticodecPrefix = [0xed, 0x01];
  static const _ed25519PublicKeyLength = 32;
  static const _ed25519SignatureLength = 64;

  /// Returns a copy of [document] with an embedded proof made by [signer].
  ///
  /// Any existing `proof` is replaced.
  static Future<Map<String, dynamic>> sign(
    Map<String, dynamic> document, {
    required TrustTaskSigner signer,
    required ProofPurpose purpose,
    DateTime? created,
  }) async {
    final unsecured = Map<String, dynamic>.of(document)..remove('proof');
    final proofConfig = <String, dynamic>{
      'type': _proofType,
      'cryptosuite': _cryptosuite,
      'created': formatTrustTaskTime(created ?? DateTime.now()),
      'verificationMethod': signer.verificationMethod,
      'proofPurpose': purpose.value,
      if (unsecured.containsKey('@context')) '@context': unsecured['@context'],
    };

    final signature = await signer.sign(_hashData(proofConfig, unsecured));
    return {
      ...unsecured,
      'proof': {...proofConfig, 'proofValue': toMultiBase(signature)},
    };
  }

  /// Verifies the embedded proof of [document].
  ///
  /// The verification method must be listed under [purpose] in the signer's
  /// DID document, resolved with [resolver]. When [expectedSigner] is given,
  /// the verification method must belong to that DID.
  ///
  /// Throws [MeetingPlaceVtcSDKException] when the proof does not verify.
  static Future<void> verify(
    Map<String, dynamic> document, {
    required ProofPurpose purpose,
    required DidResolver resolver,
    String? expectedSigner,
  }) async {
    final proof = document['proof'];
    if (proof is! Map<String, dynamic>) {
      throw MeetingPlaceVtcSDKException.invalidProof('missing proof');
    }
    if (proof['type'] != _proofType || proof['cryptosuite'] != _cryptosuite) {
      throw MeetingPlaceVtcSDKException.invalidProof('unsupported cryptosuite');
    }
    if (proof['proofPurpose'] != purpose.value) {
      throw MeetingPlaceVtcSDKException.invalidProof('unexpected purpose');
    }

    final verificationMethod = proof['verificationMethod'];
    final proofValue = proof['proofValue'];
    if (verificationMethod is! String || proofValue is! String) {
      throw MeetingPlaceVtcSDKException.invalidProof('malformed proof');
    }

    final signerDid = verificationMethod.split('#').first;
    if (expectedSigner != null && signerDid != expectedSigner) {
      throw MeetingPlaceVtcSDKException.invalidProof('unexpected signer');
    }

    final unsecured = Map<String, dynamic>.of(document)..remove('proof');
    final proofConfig = Map<String, dynamic>.of(proof)..remove('proofValue');
    if (proofConfig.containsKey('@context') &&
        !const DeepCollectionEquality().equals(
          proofConfig['@context'],
          unsecured['@context'],
        )) {
      throw MeetingPlaceVtcSDKException.invalidProof('context mismatch');
    }

    final publicKey = await _resolvePublicKey(
      resolver: resolver,
      signerDid: signerDid,
      verificationMethod: verificationMethod,
      purpose: purpose,
    );
    final signature = _decodeSignature(proofValue);

    final isValid = ed.verify(
      ed.PublicKey(publicKey),
      _hashData(proofConfig, unsecured),
      signature,
    );
    if (!isValid) {
      throw MeetingPlaceVtcSDKException.invalidProof('signature mismatch');
    }
  }

  static Uint8List _hashData(
    Map<String, dynamic> proofConfig,
    Map<String, dynamic> unsecured,
  ) {
    return Uint8List.fromList([
      ...sha256.convert(utf8.encode(JcsUtil.canonicalize(proofConfig))).bytes,
      ...sha256.convert(utf8.encode(JcsUtil.canonicalize(unsecured))).bytes,
    ]);
  }

  static Future<Uint8List> _resolvePublicKey({
    required DidResolver resolver,
    required String signerDid,
    required String verificationMethod,
    required ProofPurpose purpose,
  }) async {
    final DidDocument didDocument;
    try {
      didDocument = await resolver.resolveDid(signerDid);
    } catch (error) {
      throw MeetingPlaceVtcSDKException.invalidProof(
        'signer DID could not be resolved',
        innerException: error,
      );
    }

    final relationship = switch (purpose) {
      ProofPurpose.authentication => didDocument.authentication,
      ProofPurpose.assertionMethod => didDocument.assertionMethod,
      _ => throw MeetingPlaceVtcSDKException.invalidProof(
        'unsupported purpose',
      ),
    };
    final method = relationship.firstWhereOrNull(
      (method) =>
          _absoluteId(method.id, signerDid) ==
          _absoluteId(verificationMethod, signerDid),
    );
    if (method == null) {
      throw MeetingPlaceVtcSDKException.invalidProof(
        'verification method not authorised for purpose',
      );
    }

    final multikey = method.asMultiKey();
    final hasEd25519Prefix =
        multikey.length ==
            _ed25519MulticodecPrefix.length + _ed25519PublicKeyLength &&
        multikey[0] == _ed25519MulticodecPrefix[0] &&
        multikey[1] == _ed25519MulticodecPrefix[1];
    if (!hasEd25519Prefix) {
      throw MeetingPlaceVtcSDKException.invalidProof('key is not Ed25519');
    }
    return Uint8List.sublistView(multikey, _ed25519MulticodecPrefix.length);
  }

  static Uint8List _decodeSignature(String proofValue) {
    if (!proofValue.startsWith('z')) {
      throw MeetingPlaceVtcSDKException.invalidProof('proofValue not base58');
    }
    final Uint8List signature;
    try {
      signature = multiBaseToUint8List(proofValue);
    } catch (error) {
      throw MeetingPlaceVtcSDKException.invalidProof(
        'proofValue not decodable',
        innerException: error,
      );
    }
    if (signature.length != _ed25519SignatureLength) {
      throw MeetingPlaceVtcSDKException.invalidProof('bad signature length');
    }
    return signature;
  }

  static String _absoluteId(String id, String did) =>
      id.startsWith('#') ? '$did$id' : id;
}
