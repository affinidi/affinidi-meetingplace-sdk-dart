import 'package:meeting_place_mediator/src/utils/mediator_utils.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

class MockDidResolver implements DidResolver {
  final Map<String, DidDocument> _mockDocuments = {};

  void mockDocument(String did, DidDocument document) {
    _mockDocuments[did] = document;
  }

  @override
  Future<DidDocument> resolveDid(String did) async {
    final doc = _mockDocuments[did];
    if (doc == null) {
      throw Exception('DID not found: $did');
    }
    return doc;
  }
}

DidDocument _createDidDocument({
  required String id,
  required Map<String, dynamic> service,
}) {
  return DidDocument.fromJson({
    '@context': 'https://www.w3.org/ns/did/v1',
    'id': id,
    'service': [service],
  });
}

void main() {
  group('MediatorUtils', () {
    late MockDidResolver mockDidResolver;
    const testMediatorDid = 'did:example:123456789abcdefghi';

    setUp(() {
      mockDidResolver = MockDidResolver();
    });

    group('getMediatorEndpointByDid', () {
      test('returns HTTPS endpoint from StringEndpoint', () async {
        final didDocument = _createDidDocument(
          id: testMediatorDid,
          service: {
            'id': '$testMediatorDid#didcomm',
            'type': 'DIDCommMessaging',
            'serviceEndpoint': 'https://mediator.example.com',
          },
        );

        mockDidResolver.mockDocument(testMediatorDid, didDocument);

        final endpoint = await MediatorUtils.getMediatorEndpointByDid(
          testMediatorDid,
          didResolver: mockDidResolver,
        );

        expect(endpoint, equals('https://mediator.example.com'));
      });

      test('returns HTTPS endpoint from MapEndpoint with uri key', () async {
        final didDocument = _createDidDocument(
          id: testMediatorDid,
          service: {
            'id': '$testMediatorDid#didcomm',
            'type': 'DIDCommMessaging',
            'serviceEndpoint': {
              'uri': 'https://mediator.example.com',
              'accept': ['didcomm/v2'],
            },
          },
        );

        mockDidResolver.mockDocument(testMediatorDid, didDocument);

        final endpoint = await MediatorUtils.getMediatorEndpointByDid(
          testMediatorDid,
          didResolver: mockDidResolver,
        );

        expect(endpoint, equals('https://mediator.example.com'));
      });

      test('returns HTTPS endpoint from SetEndpoint with MapEndpoint',
          () async {
        final didDocument = _createDidDocument(
          id: testMediatorDid,
          service: {
            'id': '$testMediatorDid#didcomm',
            'type': 'DIDCommMessaging',
            'serviceEndpoint': [
              {
                'uri': 'https://mediator.example.com',
                'accept': ['didcomm/v2'],
              },
            ],
          },
        );

        mockDidResolver.mockDocument(testMediatorDid, didDocument);

        final endpoint = await MediatorUtils.getMediatorEndpointByDid(
          testMediatorDid,
          didResolver: mockDidResolver,
        );

        expect(endpoint, equals('https://mediator.example.com'));
      });

      test('returns HTTPS endpoint from SetEndpoint with StringEndpoint',
          () async {
        final didDocument = _createDidDocument(
          id: testMediatorDid,
          service: {
            'id': '$testMediatorDid#didcomm',
            'type': 'DIDCommMessaging',
            'serviceEndpoint': [
              'https://mediator.example.com',
            ],
          },
        );

        mockDidResolver.mockDocument(testMediatorDid, didDocument);

        final endpoint = await MediatorUtils.getMediatorEndpointByDid(
          testMediatorDid,
          didResolver: mockDidResolver,
        );

        expect(endpoint, equals('https://mediator.example.com'));
      });

      test('skips non-HTTPS StringEndpoint and finds HTTPS endpoint', () async {
        final didDocument = _createDidDocument(
          id: testMediatorDid,
          service: {
            'id': '$testMediatorDid#didcomm',
            'type': 'DIDCommMessaging',
            'serviceEndpoint': [
              'http://insecure.example.com',
              'https://secure.example.com',
            ],
          },
        );

        mockDidResolver.mockDocument(testMediatorDid, didDocument);

        final endpoint = await MediatorUtils.getMediatorEndpointByDid(
          testMediatorDid,
          didResolver: mockDidResolver,
        );

        expect(endpoint, equals('https://secure.example.com'));
      });

      test('skips non-HTTPS MapEndpoint and finds HTTPS endpoint', () async {
        final didDocument = _createDidDocument(
          id: testMediatorDid,
          service: {
            'id': '$testMediatorDid#didcomm',
            'type': 'DIDCommMessaging',
            'serviceEndpoint': [
              {'uri': 'http://insecure.example.com'},
              {'uri': 'https://secure.example.com'},
            ],
          },
        );

        mockDidResolver.mockDocument(testMediatorDid, didDocument);

        final endpoint = await MediatorUtils.getMediatorEndpointByDid(
          testMediatorDid,
          didResolver: mockDidResolver,
        );

        expect(endpoint, equals('https://secure.example.com'));
      });

      test('throws exception when StringEndpoint is not HTTPS', () async {
        final didDocument = _createDidDocument(
          id: testMediatorDid,
          service: {
            'id': '$testMediatorDid#didcomm',
            'type': 'DIDCommMessaging',
            'serviceEndpoint': 'http://insecure.example.com',
          },
        );

        mockDidResolver.mockDocument(testMediatorDid, didDocument);

        expect(
          () => MediatorUtils.getMediatorEndpointByDid(
            testMediatorDid,
            didResolver: mockDidResolver,
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('No valid mediator endpoint found in DID Document'),
            ),
          ),
        );
      });

      test('throws exception when MapEndpoint is not HTTPS', () async {
        final didDocument = _createDidDocument(
          id: testMediatorDid,
          service: {
            'id': '$testMediatorDid#didcomm',
            'type': 'DIDCommMessaging',
            'serviceEndpoint': {
              'uri': 'http://insecure.example.com',
            },
          },
        );

        mockDidResolver.mockDocument(testMediatorDid, didDocument);

        expect(
          () => MediatorUtils.getMediatorEndpointByDid(
            testMediatorDid,
            didResolver: mockDidResolver,
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('No valid mediator endpoint found in DID Document'),
            ),
          ),
        );
      });

      test('throws exception when SetEndpoint contains no HTTPS endpoints',
          () async {
        final didDocument = _createDidDocument(
          id: testMediatorDid,
          service: {
            'id': '$testMediatorDid#didcomm',
            'type': 'DIDCommMessaging',
            'serviceEndpoint': [
              'http://insecure1.example.com',
              {'uri': 'http://insecure2.example.com'},
            ],
          },
        );

        mockDidResolver.mockDocument(testMediatorDid, didDocument);

        expect(
          () => MediatorUtils.getMediatorEndpointByDid(
            testMediatorDid,
            didResolver: mockDidResolver,
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('No valid mediator endpoint found in DID Document'),
            ),
          ),
        );
      });

      test('throws exception when no DIDCommMessaging service exists',
          () async {
        final didDocument = _createDidDocument(
          id: testMediatorDid,
          service: {
            'id': '$testMediatorDid#other',
            'type': 'OtherService',
            'serviceEndpoint': 'https://other.example.com',
          },
        );

        mockDidResolver.mockDocument(testMediatorDid, didDocument);

        expect(
          () => MediatorUtils.getMediatorEndpointByDid(
            testMediatorDid,
            didResolver: mockDidResolver,
          ),
          throwsA(isA<StateError>()),
        );
      });

      test('throws exception when service list is empty', () async {
        final didDocument = DidDocument.fromJson({
          '@context': 'https://www.w3.org/ns/did/v1',
          'id': testMediatorDid,
          'service': <Map<String, dynamic>>[],
        });

        mockDidResolver.mockDocument(testMediatorDid, didDocument);

        expect(
          () => MediatorUtils.getMediatorEndpointByDid(
            testMediatorDid,
            didResolver: mockDidResolver,
          ),
          throwsA(isA<StateError>()),
        );
      });

      test('handles SetEndpoint with mixed endpoint types', () async {
        final didDocument = _createDidDocument(
          id: testMediatorDid,
          service: {
            'id': '$testMediatorDid#didcomm',
            'type': 'DIDCommMessaging',
            'serviceEndpoint': [
              {'uri': 'http://insecure.example.com'},
              'https://secure.example.com',
              {'uri': 'https://another.example.com'},
            ],
          },
        );

        mockDidResolver.mockDocument(testMediatorDid, didDocument);

        final endpoint = await MediatorUtils.getMediatorEndpointByDid(
          testMediatorDid,
          didResolver: mockDidResolver,
        );

        // Should return the first HTTPS endpoint found
        expect(
          endpoint,
          anyOf(
            equals('https://secure.example.com'),
            equals('https://another.example.com'),
          ),
        );
      });
    });
  });
}
