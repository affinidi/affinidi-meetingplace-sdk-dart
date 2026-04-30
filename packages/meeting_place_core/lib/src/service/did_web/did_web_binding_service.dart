import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:meeting_place_control_plane/meeting_place_control_plane.dart'
    as cp;
import 'package:ssi/ssi.dart'
    show DidManager, JcsUtil, KeyType, PublicKey, Wallet;
import 'package:uuid/uuid.dart';

import 'did_web_utils.dart';

/// Handles ADR-0103 did:web upload flow via Control Plane APIs.
class DidWebBindingService {
  DidWebBindingService({required Wallet wallet}) : _wallet = wallet;

  final Wallet _wallet;

  /// Builds and uploads the initial did:web DID document to Control Plane.
  ///
  /// [ownerDidManager] – A `DidWebManager` whose `did` is the `did:web` to bind.
  /// [matrixUserId], [accessToken], and [homeserverBaseUrl] are kept for API
  /// compatibility with existing callsites.
  /// [mediatorDid]     – Optional DIDComm mediator DID added as a service endpoint.
  Future<void> bindDid({
    required DidManager ownerDidManager,
    required String matrixUserId,
    required String accessToken,
    required cp.ControlPlaneSDK controlPlaneSDK,
    Uri? homeserverBaseUrl,
    String? mediatorDid,
  }) async {
    final controlDidDocument = await controlPlaneSDK.didManager.getDidDocument();
    final controlDid = controlDidDocument.id;
    final controlVmId = controlPlaneSDK.didManager.authentication.first;
    final controlWalletKeyId =
        (await controlPlaneSDK.didManager.getWalletKeyId(controlVmId))!;

    final ownerDidDocument = await ownerDidManager.getDidDocument();
    final did = ownerDidDocument.id;
    final authVmId = ownerDidManager.authentication.first;
    final authWalletKeyId = (await ownerDidManager.getWalletKeyId(authVmId))!;
    final authPk = await _wallet.getPublicKey(authWalletKeyId);
    final keyAgreementVmId = ownerDidManager.keyAgreement.first;
    final keyAgreementWalletKeyId =
        (await ownerDidManager.getWalletKeyId(keyAgreementVmId))!;
    final keyAgreementPk = await _wallet.getPublicKey(keyAgreementWalletKeyId);

    final didDocument = _buildDidDocument(
      did: did,
      authVerificationMethodId: authVmId,
      authPublicKey: authPk,
      keyAgreementVerificationMethodId: keyAgreementVmId,
      keyAgreementPublicKey: keyAgreementPk,
      mediatorDid: mediatorDid,
    );

    final canonicalDidDocument = JcsUtil.canonicalize(didDocument);
    final didDocumentHash = _base64UrlNoPadding(
      Uint8List.fromList(sha256.convert(utf8.encode(canonicalDidDocument)).bytes),
    );

    final nowSeconds = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    final expiresSeconds = nowSeconds + 300;
    final audienceDid = controlPlaneSDK.controlPlaneDid;
    final operation = 'did-document/upload';

    final controlProofPayload = _buildCanonicalProofPayload(
      operation: operation,
      didDocumentId: did,
      didDocumentHash: didDocumentHash,
      controlDid: controlDid,
      aud: audienceDid,
      iat: nowSeconds,
      exp: expiresSeconds,
      jti: const Uuid().v4(),
    );
    final authProofPayload = _buildCanonicalProofPayload(
      operation: operation,
      didDocumentId: did,
      didDocumentHash: didDocumentHash,
      controlDid: controlDid,
      aud: audienceDid,
      iat: nowSeconds,
      exp: expiresSeconds,
      jti: const Uuid().v4(),
    );

    final controlPublicKey = await _wallet.getPublicKey(controlWalletKeyId);
    final authPublicKey = await _wallet.getPublicKey(authWalletKeyId);

    final controlProof = _buildProofObject(
      verificationMethod: controlVmId,
      jws: await _buildDetachedJws(
        payloadCanonicalJson: controlProofPayload,
        keyId: controlWalletKeyId,
        keyType: controlPublicKey.type,
      ),
    );
    final proof = _buildProofObject(
      verificationMethod: authVmId,
      jws: await _buildDetachedJws(
        payloadCanonicalJson: authProofPayload,
        keyId: authWalletKeyId,
        keyType: authPublicKey.type,
      ),
    );

    await controlPlaneSDK.execute(
      cp.DidDocumentUploadCommand(
        didDocument: didDocument,
        controlProof: controlProof,
        proof: proof,
      ),
    );
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  Map<String, dynamic> _buildDidDocument({
    required String did,
    required String authVerificationMethodId,
    required PublicKey authPublicKey,
    required String keyAgreementVerificationMethodId,
    required PublicKey keyAgreementPublicKey,
    String? mediatorDid,
  }) {
    final verificationMethods = <Map<String, dynamic>>[
      {
        'id': authVerificationMethodId,
        'type': 'JsonWebKey2020',
        'controller': did,
        'publicKeyJwk': _buildPublicKeyJwk(authPublicKey),
      },
    ];
    if (keyAgreementVerificationMethodId != authVerificationMethodId) {
      verificationMethods.add({
        'id': keyAgreementVerificationMethodId,
        'type': 'JsonWebKey2020',
        'controller': did,
        'publicKeyJwk': _buildPublicKeyJwk(keyAgreementPublicKey),
      });
    }
    final doc = <String, dynamic>{
      '@context': [
        'https://www.w3.org/ns/did/v1',
        'https://w3id.org/security/suites/jws-2020/v1',
      ],
      'id': did,
      'verificationMethod': verificationMethods,
      'authentication': [authVerificationMethodId],
      'assertionMethod': [authVerificationMethodId],
      'keyAgreement': [keyAgreementVerificationMethodId],
    };
    if (mediatorDid != null) {
      doc['service'] = [
        {
          'id': '$did#didcomm',
          'type': 'DIDCommMessaging',
          'serviceEndpoint': {'uri': mediatorDid},
        },
      ];
    }
    return doc;
  }

  String _buildCanonicalProofPayload({
    required String operation,
    required String didDocumentId,
    required String didDocumentHash,
    required String controlDid,
    required String aud,
    required int iat,
    required int exp,
    required String jti,
  }) {
    return JcsUtil.canonicalize({
      'operation': operation,
      'didDocumentId': didDocumentId,
      'didDocumentHash': didDocumentHash,
      'controlDid': controlDid,
      'aud': aud,
      'iat': iat,
      'exp': exp,
      'jti': jti,
    });
  }

  Map<String, dynamic> _buildProofObject({
    required String verificationMethod,
    required String jws,
  }) {
    return {
      'type': 'JsonWebSignature2020',
      'created': DateTime.now().toUtc().toIso8601String(),
      'verificationMethod': verificationMethod,
      'proofPurpose': 'authentication',
      'jws': jws,
    };
  }

  Future<String> _buildDetachedJws({
    required String payloadCanonicalJson,
    required String keyId,
    required KeyType keyType,
  }) async {
    final alg = _algForKeyType(keyType);
    final headerJson = jsonEncode({'alg': alg, 'typ': 'JWT'});
    final headerB64 =
        _base64UrlNoPadding(Uint8List.fromList(utf8.encode(headerJson)));
    final payloadB64 = _base64UrlNoPadding(
      Uint8List.fromList(utf8.encode(payloadCanonicalJson)),
    );
    final signingInput = '$headerB64.$payloadB64';
    final signature = await _wallet.sign(
      Uint8List.fromList(utf8.encode(signingInput)),
      keyId: keyId,
    );
    final signatureB64 = _base64UrlNoPadding(signature);
    return '$headerB64..$signatureB64';
  }

  String _algForKeyType(KeyType keyType) {
    switch (keyType) {
      case KeyType.p256:
        return 'ES256';
      case KeyType.ed25519:
        return 'EdDSA';
      default:
        throw UnsupportedError('Unsupported key type for detached JWS: $keyType');
    }
  }

  Map<String, dynamic> _buildPublicKeyJwk(PublicKey pk) {
    if (pk.type == KeyType.p256) {
      final uncompressed = uncompressP256(pk.bytes); // from did_web_utils.dart
      return {
        'kty': 'EC',
        'crv': 'P-256',
        'x': _base64UrlNoPadding(uncompressed.sublist(1, 33)),
        'y': _base64UrlNoPadding(uncompressed.sublist(33, 65)),
      };
    }
    return {'kty': 'OKP', 'crv': 'Ed25519', 'x': _base64UrlNoPadding(pk.bytes)};
  }

  String _base64UrlNoPadding(Uint8List bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');

}
