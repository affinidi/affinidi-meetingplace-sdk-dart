import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:ssi/ssi.dart'
    show DidManager, JcsUtil, KeyType, PublicKey, Wallet, didWebToUri;

import 'did_web_utils.dart';

/// Binds a `did:web` DID Document to a pairwise Matrix account on the Synapse
/// homeserver via the MeetingPlace v1 custom endpoints:
///
///   POST /_matrix/meetingplace/v1/did/bind/challenge
///   PUT  /_matrix/meetingplace/v1/did/bind
///
/// The DID string and key material are taken from a [DidManager] (typically a
/// `DidWebManager` created by [ConnectionManager.generateDidWeb]).
class DidWebBindingService {
  DidWebBindingService({required Wallet wallet}) : _wallet = wallet;

  final Wallet _wallet;

  /// Performs the full challenge → sign → publish flow.
  ///
  /// [ownerDidManager] – A `DidWebManager` whose `did` is the `did:web` to bind.
  /// [matrixUserId]    – Full Matrix user ID (`@<localpart>:<hs-domain>`).
  /// [accessToken]     – Bearer token for the authenticated Matrix session.
  /// [homeserverBaseUrl] – Optional explicit Matrix homeserver origin. When
  /// provided, its scheme is preserved, allowing local `http://...`
  /// homeservers in development.
  /// [mediatorDid]     – Optional DIDComm mediator DID added as a service endpoint.
  Future<void> bindDid({
    required DidManager ownerDidManager,
    required String matrixUserId,
    required String accessToken,
    Uri? homeserverBaseUrl,
    String? mediatorDid,
  }) async {
    // Resolve DID string and key material from the manager.
    final did = (await ownerDidManager.getDidDocument()).id;
    final opaqueId = did.split(':').last;
    final vmId = ownerDidManager.authentication.first;
    final walletKeyId = (await ownerDidManager.getWalletKeyId(vmId))!;
    final pk = await _wallet.getPublicKey(walletKeyId);

    // Derive homeserver base URL from the did:web (strip /connections/<id>/did.json path).
    final didJsonUri = didWebToUri(did);
    final homeserver = _originFromUri(
      homeserverBaseUrl ??
          Uri(
            scheme: didJsonUri.scheme,
            host: didJsonUri.host,
            port: didJsonUri.hasPort ? didJsonUri.port : null,
          ),
    );

    final didDocument = _buildDidDocument(
      did: did,
      pk: pk,
      mediatorDid: mediatorDid,
    );

    final dio = Dio(
      BaseOptions(
        baseUrl: homeserver.toString(),

        headers: {'Authorization': 'Bearer $accessToken'},
        connectTimeout: const Duration(seconds: 35),
        receiveTimeout: const Duration(seconds: 35),
      ),
    );

    // Step 1 – request challenge nonce
    final challengeResp = await dio.post<Map<String, dynamic>>(
      '/_matrix/meetingplace/v1/did/bind/challenge',
      data: {'did': did, 'opaqueId': opaqueId, 'matrixId': matrixUserId},
    );
    final nonce = challengeResp.data!['nonce'] as String;
    final aud = challengeResp.data!['aud'] as String;

    // Step 2 – sign canonical proof payload (keys sorted by JCS)
    final canonicalJson = JcsUtil.canonicalize({
      'aud': aud,
      'did': did,
      'matrixId': matrixUserId,
      'nonce': nonce,
    });
    final rawSignature = await _wallet.sign(
      Uint8List.fromList(utf8.encode(canonicalJson)),
      keyId: walletKeyId,
    );
    // The server's verifier expects DER-encoded ASN.1 for P-256.
    // The ssi wallet returns compact r||s (64 bytes); convert accordingly.
    final signature = pk.type == KeyType.p256
        ? _compactToDer(rawSignature)
        : rawSignature;

    // Step 3 – publish (bind)
    await dio.put<void>(
      '/_matrix/meetingplace/v1/did/bind',
      data: {
        'did': did,
        'opaqueId': opaqueId,
        'matrixId': matrixUserId,
        'didDocument': didDocument,
        'didProof': {
          'type': 'DIDKeySignature',
          'created': DateTime.now().toUtc().toIso8601String(),
          'nonce': nonce,
          'aud': aud,
          'verificationMethod': '#auth',
          'signature': _base64UrlNoPadding(signature),
        },
      },
    );
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  Uri _originFromUri(Uri uri) {
    return Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
    );
  }

  Map<String, dynamic> _buildDidDocument({
    required String did,
    required PublicKey pk,
    String? mediatorDid,
  }) {
    final verificationMethodId = '$did#auth';
    final doc = <String, dynamic>{
      '@context': [
        'https://www.w3.org/ns/did/v1',
        'https://w3id.org/security/suites/jws-2020/v1',
      ],
      'id': did,
      'verificationMethod': [
        {
          'id': verificationMethodId,
          'type': 'JsonWebKey2020',
          'controller': did,
          'publicKeyJwk': _buildPublicKeyJwk(pk),
        },
      ],
      'authentication': [verificationMethodId],
      'assertionMethod': [verificationMethodId],
      'keyAgreement': [verificationMethodId],
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

  /// Converts a compact ECDSA signature (r||s, 64 bytes for P-256) into
  /// DER-encoded ASN.1 SEQUENCE { INTEGER r, INTEGER s } as expected by the
  /// server's cryptography.hazmat verifier.
  Uint8List _compactToDer(Uint8List compact) {
    assert(compact.length == 64, 'Expected 64-byte compact P-256 signature');

    // DER INTEGER: prepend 0x00 if high bit is set to avoid sign bit confusion.
    Uint8List _derInt(Uint8List v) {
      // Strip leading zeros but keep at least one byte.
      int start = 0;
      while (start < v.length - 1 && v[start] == 0) {
        start++;
      }
      final trimmed = v.sublist(start);
      if (trimmed[0] >= 0x80) {
        final padded = Uint8List(trimmed.length + 1);
        padded.setRange(1, padded.length, trimmed);
        return padded;
      }
      return trimmed;
    }

    final rDer = _derInt(compact.sublist(0, 32));
    final sDer = _derInt(compact.sublist(32, 64));
    final seqContentLen = 2 + rDer.length + 2 + sDer.length;

    final out = Uint8List(2 + seqContentLen);
    int i = 0;
    out[i++] = 0x30; // SEQUENCE
    out[i++] = seqContentLen;
    out[i++] = 0x02; // INTEGER r
    out[i++] = rDer.length;
    out.setRange(i, i + rDer.length, rDer);
    i += rDer.length;
    out[i++] = 0x02; // INTEGER s
    out[i++] = sDer.length;
    out.setRange(i, i + sDer.length, sDer);
    return out;
  }
}
