import 'package:meeting_place_vtc/meeting_place_vtc.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

import '../utils/fakes.dart';

const _vtcDid = 'did:webvh:QmCommScid:community.example';

DidDocument _document(List<Map<String, dynamic>> services, {String? id}) {
  return DidDocument.fromJson({
    '@context': ['https://www.w3.org/ns/did/v1'],
    'id': id ?? _vtcDid,
    'service': services,
  });
}

Matcher _throwsCode(MeetingPlaceVtcSDKErrorCode code) => throwsA(
  isA<MeetingPlaceVtcSDKException>().having((e) => e.code, 'code', code),
);

void main() {
  group('VtcResolver', () {
    test('takes the endpoints from the DID document by type', () async {
      final resolver = VtcResolver(
        didResolver: FakeDidResolver({
          _vtcDid: _document([
            {
              'id': '$_vtcDid#a',
              'type': 'TrustTaskHTTPS',
              'serviceEndpoint': 'http://community.example/v1',
            },
            {
              'id': '$_vtcDid#b',
              'type': 'TrustTaskHTTPS',
              'serviceEndpoint': 'https://u@community.example/v1',
            },
            {
              'id': '$_vtcDid#trust-tasks',
              'type': 'TrustTaskHTTPS',
              'serviceEndpoint': {'uri': 'https://community.example/v1'},
            },
            {
              'id': '$_vtcDid#sign-in-portal',
              'type': 'SignInPortal',
              'serviceEndpoint': 'https://community.example/members/',
            },
          ]),
        }),
      );

      final vtc = await resolver.resolve(_vtcDid);

      expect(vtc.did, _vtcDid);
      expect(vtc.trustTaskBase, Uri.parse('https://community.example/v1'));
      expect(vtc.signInOrigin, 'https://community.example');
    });

    test('refuses a document without a sign-in portal', () {
      final resolver = VtcResolver(
        didResolver: FakeDidResolver({
          _vtcDid: _document([
            {
              'id': '$_vtcDid#trust-tasks',
              'type': 'TrustTaskHTTPS',
              'serviceEndpoint': 'https://community.example/v1',
            },
          ]),
        }),
      );

      expect(
        resolver.resolve(_vtcDid),
        _throwsCode(MeetingPlaceVtcSDKErrorCode.signInNotOffered),
      );
    });

    test('refuses an endpoint with a port', () {
      final resolver = VtcResolver(
        didResolver: FakeDidResolver({
          _vtcDid: _document([
            {
              'id': '$_vtcDid#trust-tasks',
              'type': 'TrustTaskHTTPS',
              'serviceEndpoint': 'https://community.example:443/v1',
            },
            {
              'id': '$_vtcDid#sign-in-portal',
              'type': 'SignInPortal',
              'serviceEndpoint': 'https://community.example/members/',
            },
          ]),
        }),
      );

      expect(
        resolver.resolve(_vtcDid),
        _throwsCode(MeetingPlaceVtcSDKErrorCode.signInNotOffered),
      );
    });

    test('refuses a document for another DID', () {
      final resolver = VtcResolver(
        didResolver: FakeDidResolver({
          _vtcDid: _document([], id: 'did:webvh:QmOther:other.example'),
        }),
      );

      expect(
        resolver.resolve(_vtcDid),
        _throwsCode(MeetingPlaceVtcSDKErrorCode.didResolutionFailed),
      );
    });

    test('reports a DID that does not resolve', () {
      final resolver = VtcResolver(didResolver: FakeDidResolver());

      expect(
        resolver.resolve(_vtcDid),
        _throwsCode(MeetingPlaceVtcSDKErrorCode.didResolutionFailed),
      );
    });
  });
}
