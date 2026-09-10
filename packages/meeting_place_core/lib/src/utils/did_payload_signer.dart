import 'dart:convert';
import 'dart:typed_data';

import 'package:ssi/ssi.dart';

import 'jcs_serializer.dart';

/// Signs and verifies a JSON payload as a compact JWS using a DID key,
/// so a recipient can prove a payload was authored by a specific DID
/// regardless of which transport (DIDComm, Matrix, or otherwise) carried it.
///
/// The payload is canonicalized with [jcsSerializer] (RFC 8785) before
/// signing so the same payload always signs to the same bytes.
class DidPayloadSigner {
  const DidPayloadSigner();

  /// Signs [payload] with [didManager]'s key at [verificationMethodId],
  /// returning a compact JWS (`header.payload.signature`, base64url,
  /// no padding).
  Future<String> sign({
    required Map<String, dynamic> payload,
    required DidManager didManager,
    required String verificationMethodId,
  }) async {
    final walletKeyId = await didManager.getWalletKeyId(verificationMethodId);
    final publicKey = await didManager.wallet.getPublicKey(walletKeyId!);
    final alg = _jwsAlgorithm(publicKey.type);

    final header = {'alg': alg, 'kid': verificationMethodId};
    final encodedHeader = _base64UrlNoPadEncode(
      jcsSerializer.serializeObjectToUtf8(header),
    );
    final encodedPayload = _base64UrlNoPadEncode(
      jcsSerializer.serializeObjectToUtf8(payload),
    );

    final signingInput = utf8.encode('$encodedHeader.$encodedPayload');
    final signature = await didManager.sign(
      Uint8List.fromList(signingInput),
      verificationMethodId,
    );

    final encodedSignature = _base64UrlNoPadEncode(signature);
    return '$encodedHeader.$encodedPayload.$encodedSignature';
  }

  /// Verifies [jws] was signed by [expectedSignerDid], resolving that DID's
  /// current document via [didResolver] to obtain the verification key.
  ///
  /// Returns the decoded payload map if the signature is valid. Returns
  /// `null` if the JWS is malformed, the signature does not verify, or the
  /// `kid` in the JWS header does not belong to [expectedSignerDid].
  Future<Map<String, dynamic>?> verify({
    required String jws,
    required String expectedSignerDid,
    required DidResolver didResolver,
  }) async {
    final parts = jws.split('.');
    if (parts.length != 3) return null;

    final Map<String, dynamic> header;
    final Map<String, dynamic> payload;
    try {
      header =
          jsonDecode(utf8.decode(_base64UrlNoPadDecode(parts[0])))
              as Map<String, dynamic>;
      payload =
          jsonDecode(utf8.decode(_base64UrlNoPadDecode(parts[1])))
              as Map<String, dynamic>;
    } on FormatException {
      return null;
    }

    final kid = header['kid'] as String?;
    final alg = header['alg'] as String?;
    if (kid == null || alg == null) return null;
    if (!kid.startsWith(expectedSignerDid)) return null;

    final signatureScheme = _signatureScheme(alg);
    if (signatureScheme == null) return null;

    final DidVerifier verifier;
    try {
      verifier = await DidVerifier.create(
        algorithm: signatureScheme,
        issuerDid: expectedSignerDid,
        kid: kid,
        didResolver: didResolver,
      );
    } on Object {
      return null;
    }

    final signingInput = utf8.encode('${parts[0]}.${parts[1]}');
    final signature = _base64UrlNoPadDecode(parts[2]);
    final isValid = verifier.verify(
      Uint8List.fromList(signingInput),
      signature,
    );

    return isValid ? payload : null;
  }

  Uint8List _base64UrlNoPadDecode(String value) {
    final normalized = base64Url.normalize(value);
    return base64Url.decode(normalized);
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

  SignatureScheme? _signatureScheme(String alg) {
    return switch (alg) {
      'EdDSA' || 'Ed25519' => SignatureScheme.ed25519,
      'ES256' => SignatureScheme.ecdsa_p256_sha256,
      'ES384' => SignatureScheme.ecdsa_p384_sha384,
      'ES512' => SignatureScheme.ecdsa_p521_sha512,
      'ES256K' => SignatureScheme.ecdsa_secp256k1_sha256,
      _ => null,
    };
  }
}
