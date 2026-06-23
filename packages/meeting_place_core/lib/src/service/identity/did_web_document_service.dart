import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:meeting_place_control_plane/meeting_place_control_plane.dart'
    hide ContactCard;
import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';

class DidWebDocumentService {
  DidWebDocumentService({
    required ControlPlaneSDK controlPlaneSDK,
    required DidManager rootDidManager,
    String? audience,
  }) : _controlPlaneSDK = controlPlaneSDK,
       _rootDidManager = rootDidManager,
       _audience = audience ?? 'https://controlplane.example.com';

  final ControlPlaneSDK _controlPlaneSDK;
  final DidManager _rootDidManager;
  final String _audience;
  static const int _expiryDuration = 300; // 5 minutes in seconds

  Future<void> register({
    required DidManager didManager,
    required DidDocument didDocument,
  }) async {
    final rootDidDoc = await _rootDidManager.getDidDocument();
    final didDocBytes = _canonicalizeJson(didDocument.toJson());
    final didDocHash = _sha256Hash(didDocBytes);

    // Build once so both proofs share the same payload (identical aud,
    // jti, iat, exp).
    // The CP verifier rejects if controlProof and proof have any payload
    // difference.
    final sharedPayload = _buildProofPayload(
      operation: 'did-document/upload',
      didDocumentId: didDocument.id,
      didDocumentHash: didDocHash,
      controlDid: rootDidDoc.id,
    );

    final controlProof = await _createControlProof(
      didDocument,
      rootDidDoc: rootDidDoc,
      didDocumentHash: didDocHash,
      sharedPayload: sharedPayload,
    );
    final proof = await _createDocumentProof(
      didManager,
      didDocument,
      controlDid: rootDidDoc.id,
      didDocumentHash: didDocHash,
      sharedPayload: sharedPayload,
    );

    await _controlPlaneSDK.execute(
      UploadDidWebDocumentCommand(
        didDocument: didDocument.toJson(),
        controlProof: controlProof,
        proof: proof,
      ),
    );
  }

  Future<DidWebProof> _createControlProof(
    DidDocument newDidDocument, {
    required DidDocument rootDidDoc,
    required String didDocumentHash,
    required Map<String, dynamic> sharedPayload,
  }) async {
    final authVm = rootDidDoc.authentication.first;
    final authKeyId = _resolveVmId(authVm, rootDidDoc.id);

    final payload = sharedPayload;

    final jws = await _createCompactJws(
      payload: payload,
      didManager: _rootDidManager,
      verificationMethodId: authKeyId,
    );

    return DidWebProof(
      type: 'JsonWebSignature2020',
      created: DateTime.now().toUtc().toIso8601String(),
      verificationMethod: authKeyId,
      proofPurpose: 'authentication',
      jws: jws,
    );
  }

  Future<DidWebProof> _createDocumentProof(
    DidManager didManager,
    DidDocument didDocument, {
    required String controlDid,
    required String didDocumentHash,
    required Map<String, dynamic> sharedPayload,
  }) async {
    final authVm = didDocument.authentication.first;
    final authKeyId = _resolveVmId(authVm, didDocument.id);

    final payload = sharedPayload;

    final jws = await _createCompactJws(
      payload: payload,
      didManager: didManager,
      verificationMethodId: authKeyId,
    );

    return DidWebProof(
      type: 'JsonWebSignature2020',
      created: DateTime.now().toUtc().toIso8601String(),
      verificationMethod: authKeyId,
      proofPurpose: 'authentication',
      jws: jws,
    );
  }

  Map<String, dynamic> _buildProofPayload({
    required String operation,
    required String didDocumentId,
    required String didDocumentHash,
    required String controlDid,
  }) {
    final now = DateTime.now();
    final iatSeconds = (now.millisecondsSinceEpoch / 1000).floor();
    final expSeconds = iatSeconds + _expiryDuration;

    final payload = {
      'operation': operation,
      'didDocumentId': didDocumentId,
      'didDocumentHash': didDocumentHash,
      'controlDid': controlDid,
      'aud': _audience,
      'iat': iatSeconds,
      'exp': expSeconds,
      'jti': const Uuid().v4(),
    };

    return payload;
  }

  Future<String> _createCompactJws({
    required Map<String, dynamic> payload,
    required DidManager didManager,
    required String verificationMethodId,
  }) async {
    final walletKeyId = await didManager.getWalletKeyId(verificationMethodId);
    final publicKey = await didManager.wallet.getPublicKey(walletKeyId!);
    final alg = _jwsAlgorithm(publicKey.type);

    final header = {'alg': alg, 'kid': verificationMethodId};
    final encodedHeader = _base64UrlNoPadEncode(_canonicalizeJson(header));

    final payloadBytes = _canonicalizeJson(payload);
    final encodedPayload = _base64UrlNoPadEncode(payloadBytes);

    final signingInput = utf8.encode('$encodedHeader.$encodedPayload');
    final signature = await didManager.sign(
      Uint8List.fromList(signingInput),
      verificationMethodId,
    );

    final encodedSignature = _base64UrlNoPadEncode(signature);
    return '$encodedHeader.$encodedPayload.$encodedSignature';
  }

  Uint8List _canonicalizeJson(Map<String, dynamic> json) {
    final canonical = _sortedJsonEncode(json);
    return Uint8List.fromList(utf8.encode(canonical));
  }

  String _sortedJsonEncode(dynamic obj) {
    if (obj is Map) {
      final sortedKeys = obj.keys.cast<String>().toList()..sort();
      final parts = sortedKeys.map((key) {
        final keyJson = jsonEncode(key);
        final valueJson = _sortedJsonEncode(obj[key]);
        return '$keyJson:$valueJson';
      });
      return '{${parts.join(',')}}';
    } else if (obj is List) {
      final parts = obj.map(_sortedJsonEncode);
      return '[${parts.join(',')}]';
    } else if (obj is String) {
      return jsonEncode(obj);
    } else if (obj == null) {
      return 'null';
    } else if (obj is bool) {
      return obj.toString();
    } else if (obj is num) {
      return obj.toString();
    }
    return jsonEncode(obj);
  }

  String _sha256Hash(Uint8List bytes) {
    final digest = sha256.convert(bytes);
    return _base64UrlNoPadEncode(digest.bytes);
  }

  String _resolveVmId(VerificationMethod vm, String didId) {
    final id = vm.id;
    if (id.startsWith('#')) {
      return '$didId$id';
    }
    return id;
  }

  String _base64UrlNoPadEncode(List<int> bytes) {
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  String _jwsAlgorithm(KeyType keyType) {
    return switch (keyType) {
      KeyType.ed25519 => 'EdDSA',
      KeyType.p256 => 'ES256',
      KeyType.p384 => 'ES384',
      KeyType.p521 => 'ES512',
      KeyType.secp256k1 => 'ES256K',
      _ => throw UnsupportedError('Unsupported key type: $keyType'),
    };
  }
}
