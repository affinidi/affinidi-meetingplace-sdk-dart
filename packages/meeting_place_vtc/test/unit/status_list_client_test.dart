import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:meeting_place_vtc/meeting_place_vtc.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

import '../utils/fakes.dart';

const _listUrl = 'https://community.example/v1/status-lists/revocation';
const _listBytes = 16;

Matcher _throwsCode(MeetingPlaceVtcSDKErrorCode code) => throwsA(
  isA<MeetingPlaceVtcSDKException>().having((e) => e.code, 'code', code),
);

void main() {
  final issuer = Ed25519DidKeySigner.fromSeed(
    Uint8List.fromList(List.filled(32, 7)),
  );
  final other = Ed25519DidKeySigner.fromSeed(
    Uint8List.fromList(List.filled(32, 9)),
  );
  final now = DateTime.utc(2026, 11, 5, 10);
  late FakeHttpAdapter adapter;
  late StatusListClient client;

  Map<String, dynamic> credential({
    bool revocable = true,
    Map<String, dynamic>? status,
    String url = _listUrl,
    String index = '42',
  }) => {
    '@context': ['https://www.w3.org/ns/credentials/v2'],
    'id': 'urn:uuid:card',
    'type': ['VerifiableCredential', 'MembershipCredential'],
    'issuer': issuer.did,
    'credentialSubject': {'id': 'did:webvh:persona'},
    if (revocable)
      'credentialStatus':
          status ??
          {
            'id': '$url#$index',
            'type': 'BitstringStatusListEntry',
            'statusPurpose': 'revocation',
            'statusListIndex': index,
            'statusListCredential': url,
          },
  };

  String encode(Set<int> revoked) {
    final bits = Uint8List(_listBytes);
    for (final index in revoked) {
      bits[index ~/ 8] |= 1 << (7 - index % 8);
    }
    final gzip = const GZipEncoder().encodeBytes(bits);
    return 'u${base64Url.encode(gzip).replaceAll('=', '')}';
  }

  Future<Map<String, dynamic>> list({
    Set<int> revoked = const {},
    Ed25519DidKeySigner? signer,
    String? issuerDid,
    String purpose = 'revocation',
    String? validUntil,
  }) => EddsaJcs2022.sign(
    {
      '@context': ['https://www.w3.org/ns/credentials/v2'],
      'id': _listUrl,
      'type': ['VerifiableCredential', 'BitstringStatusListCredential'],
      'issuer': issuerDid ?? issuer.did,
      'validFrom': '2026-11-05T09:00:00Z',
      'validUntil': ?validUntil,
      'credentialSubject': {
        'id': '$_listUrl#list',
        'type': 'BitstringStatusList',
        'statusPurpose': purpose,
        'encodedList': encode(revoked),
      },
    },
    signer: signer ?? issuer,
    purpose: ProofPurpose.assertionMethod,
  );

  void serve(Object? body, {int status = 200}) =>
      adapter.getHandler = (uri) async => (status, body);

  setUp(() {
    adapter = FakeHttpAdapter();
    client = StatusListClient(
      dio: Dio()..httpClientAdapter = adapter,
      now: () => now,
    );
  });

  group('StatusListClient.check', () {
    test('reads a clear bit as valid, with the signed list', () async {
      final served = await list(revoked: {41, 43});
      serve(served);

      final check = await client.check(credential());

      expect(check.state, CredentialStatusState.valid);
      expect(check.index, 42);
      expect(check.statusList, Uri.parse(_listUrl));
      expect(check.statusListCredential, served);
      expect(check.checkedAt, now);
      expect(adapter.requests.single.options.uri, Uri.parse(_listUrl));
    });

    test('reads a set bit as revoked', () async {
      serve(await list(revoked: {42}));

      final check = await client.check(credential());

      expect(check.state, CredentialStatusState.revoked);
    });

    test('reads bit 0 as the first byte\'s most significant bit', () async {
      serve(await list(revoked: {0}));

      expect(
        (await client.check(credential(index: '0'))).state,
        CredentialStatusState.revoked,
      );
      expect(
        (await client.check(credential(index: '7'))).state,
        CredentialStatusState.valid,
      );
    });

    test('says a credential without a status list cannot be revoked', () async {
      final check = await client.check(credential(revocable: false));

      expect(check.state, CredentialStatusState.noStatus);
      expect(check.statusListCredential, isNull);
      expect(adapter.requests, isEmpty);
    });

    test('verifies one proof of a set', () async {
      final signed = await list(revoked: {42});
      signed['proof'] = [
        {'type': 'DataIntegrityProof', 'cryptosuite': 'mldsa44-jcs-2024'},
        signed['proof'],
      ];
      serve(signed);

      expect(
        (await client.check(credential())).state,
        CredentialStatusState.revoked,
      );
    });

    test('refuses a list another key signed', () async {
      serve(await list(signer: other));

      expect(
        client.check(credential()),
        _throwsCode(MeetingPlaceVtcSDKErrorCode.invalidProof),
      );
    });

    test('refuses a list changed after signing', () async {
      final signed = await list();
      (signed['credentialSubject'] as Map<String, dynamic>)['encodedList'] =
          encode({42});
      serve(signed);

      expect(
        client.check(credential()),
        _throwsCode(MeetingPlaceVtcSDKErrorCode.invalidProof),
      );
    });

    test('refuses a list of another issuer', () async {
      serve(await list(signer: other, issuerDid: other.did));

      expect(
        client.check(credential()),
        _throwsCode(MeetingPlaceVtcSDKErrorCode.invalidDocument),
      );
    });

    test('refuses a list for another purpose', () async {
      serve(await list(purpose: 'suspension'));

      expect(
        client.check(credential()),
        _throwsCode(MeetingPlaceVtcSDKErrorCode.invalidDocument),
      );
    });

    test('refuses a list no longer valid', () async {
      serve(await list(validUntil: '2026-11-05T09:30:00Z'));

      expect(
        client.check(credential()),
        _throwsCode(MeetingPlaceVtcSDKErrorCode.invalidDocument),
      );
    });

    test('refuses a list published under another address', () async {
      serve(await list());

      expect(
        client.check(credential(url: 'https://elsewhere.example/list')),
        _throwsCode(MeetingPlaceVtcSDKErrorCode.invalidDocument),
      );
    });

    test('refuses a list not served over HTTPS', () {
      expect(
        client.check(credential(url: 'http://community.example/list')),
        _throwsCode(MeetingPlaceVtcSDKErrorCode.invalidDocument),
      );
      expect(adapter.requests, isEmpty);
    });

    test('refuses an index beyond the list', () async {
      serve(await list());

      expect(
        client.check(credential(index: '${_listBytes * 8}')),
        _throwsCode(MeetingPlaceVtcSDKErrorCode.invalidDocument),
      );
    });

    test('refuses a status entry it cannot read', () {
      expect(
        client.check(
          credential(
            status: {
              'type': 'BitstringStatusListEntry',
              'statusPurpose': 'suspension',
            },
          ),
        ),
        _throwsCode(MeetingPlaceVtcSDKErrorCode.invalidDocument),
      );
    });

    test('says when the list cannot be fetched', () async {
      serve('<html>down</html>', status: 503);

      expect(
        client.check(credential()),
        _throwsCode(MeetingPlaceVtcSDKErrorCode.transportFailed),
      );
    });
  });
}
