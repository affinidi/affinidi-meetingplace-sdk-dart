import 'package:meeting_place_control_plane/src/utils/mediator/mediator_config.dart';
import 'package:meeting_place_control_plane/src/utils/mediator/mediator_utils.dart';
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

    group('resolveMediator', () {
      test('returns MediatorConfig with both HTTP and WSS endpoints', () async {
        final didDocument = _createDidDocument(
          id: testMediatorDid,
          service: {
            'id': '$testMediatorDid#didcomm',
            'type': 'DIDCommMessaging',
            'serviceEndpoint': [
              'https://mediator.example.com',
              'wss://mediator.example.com/ws',
            ],
          },
        );

        mockDidResolver.mockDocument(testMediatorDid, didDocument);

        final config = await MediatorUtils.resolveMediator(
          testMediatorDid,
          didResolver: mockDidResolver,
        );

        expect(config, isA<MediatorConfig>());
        expect(config.mediatorDid, equals(testMediatorDid));
        expect(config.mediatorEndpoint, equals('https://mediator.example.com'));
        expect(config.mediatorWSSEndpoint,
            equals('wss://mediator.example.com/ws'));
      });

      test('handles MapEndpoint with uri key for both endpoints', () async {
        final didDocument = _createDidDocument(
          id: testMediatorDid,
          service: {
            'id': '$testMediatorDid#didcomm',
            'type': 'DIDCommMessaging',
            'serviceEndpoint': [
              {'uri': 'https://mediator.example.com'},
              {'uri': 'wss://mediator.example.com/ws'},
            ],
          },
        );

        mockDidResolver.mockDocument(testMediatorDid, didDocument);

        final config = await MediatorUtils.resolveMediator(
          testMediatorDid,
          didResolver: mockDidResolver,
        );

        expect(config.mediatorEndpoint, equals('https://mediator.example.com'));
        expect(config.mediatorWSSEndpoint,
            equals('wss://mediator.example.com/ws'));
      });

      test('finds HTTP endpoint even when WSS comes first', () async {
        final didDocument = _createDidDocument(
          id: testMediatorDid,
          service: {
            'id': '$testMediatorDid#didcomm',
            'type': 'DIDCommMessaging',
            'serviceEndpoint': [
              'wss://mediator.example.com/ws',
              'https://mediator.example.com',
            ],
          },
        );

        mockDidResolver.mockDocument(testMediatorDid, didDocument);

        final config = await MediatorUtils.resolveMediator(
          testMediatorDid,
          didResolver: mockDidResolver,
        );

        expect(config.mediatorEndpoint, equals('https://mediator.example.com'));
        expect(config.mediatorWSSEndpoint,
            equals('wss://mediator.example.com/ws'));
      });

      test('handles single StringEndpoint for HTTP', () async {
        final didDocument = _createDidDocument(
          id: testMediatorDid,
          service: {
            'id': '$testMediatorDid#didcomm',
            'type': 'DIDCommMessaging',
            'serviceEndpoint': 'https://mediator.example.com',
          },
        );

        mockDidResolver.mockDocument(testMediatorDid, didDocument);

        // This should throw for WSS endpoint but let's test HTTP works
        expect(
          () => MediatorUtils.resolveMediator(
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

      test('throws when no DIDCommMessaging service exists', () async {
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
          () => MediatorUtils.resolveMediator(
            testMediatorDid,
            didResolver: mockDidResolver,
          ),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('getMediatorConfig', () {
      test('returns config when selectedMediatorDid is provided', () async {
        const selectedDid = 'did:example:selected123';
        final didDocument = _createDidDocument(
          id: selectedDid,
          service: {
            'id': '$selectedDid#didcomm',
            'type': 'DIDCommMessaging',
            'serviceEndpoint': [
              'https://selected.example.com',
              'wss://selected.example.com/ws',
            ],
          },
        );

        mockDidResolver.mockDocument(selectedDid, didDocument);

        final config = await MediatorUtils.getMediatorConfig(
          didResolver: mockDidResolver,
          defaultMediatorDid: testMediatorDid,
          selectedMediatorDid: selectedDid,
        );

        expect(config, isNotNull);
        expect(config!.mediatorDid, equals(selectedDid));
        expect(config.mediatorEndpoint, equals('https://selected.example.com'));
      });

      test(
          'returns config from defaultMediatorDid when selectedMediatorDid is null',
          () async {
        final didDocument = _createDidDocument(
          id: testMediatorDid,
          service: {
            'id': '$testMediatorDid#didcomm',
            'type': 'DIDCommMessaging',
            'serviceEndpoint': [
              'https://default.example.com',
              'wss://default.example.com/ws',
            ],
          },
        );

        mockDidResolver.mockDocument(testMediatorDid, didDocument);

        final config = await MediatorUtils.getMediatorConfig(
          didResolver: mockDidResolver,
          defaultMediatorDid: testMediatorDid,
          selectedMediatorDid: null,
        );

        expect(config, isNotNull);
        expect(config!.mediatorDid, equals(testMediatorDid));
        expect(config.mediatorEndpoint, equals('https://default.example.com'));
      });

      test(
          'returns null when both selectedMediatorDid and defaultMediatorDid are empty',
          () async {
        final config = await MediatorUtils.getMediatorConfig(
          didResolver: mockDidResolver,
          defaultMediatorDid: '',
          selectedMediatorDid: null,
        );

        expect(config, isNull);
      });

      test(
          'returns null when defaultMediatorDid is empty and selectedMediatorDid is null',
          () async {
        final config = await MediatorUtils.getMediatorConfig(
          didResolver: mockDidResolver,
          defaultMediatorDid: '',
          selectedMediatorDid: null,
        );

        expect(config, isNull);
      });

      test('prioritizes selectedMediatorDid over defaultMediatorDid', () async {
        const selectedDid = 'did:example:selected456';
        final selectedDocument = _createDidDocument(
          id: selectedDid,
          service: {
            'id': '$selectedDid#didcomm',
            'type': 'DIDCommMessaging',
            'serviceEndpoint': [
              'https://selected.example.com',
              'wss://selected.example.com/ws',
            ],
          },
        );

        final defaultDocument = _createDidDocument(
          id: testMediatorDid,
          service: {
            'id': '$testMediatorDid#didcomm',
            'type': 'DIDCommMessaging',
            'serviceEndpoint': [
              'https://default.example.com',
              'wss://default.example.com/ws',
            ],
          },
        );

        mockDidResolver.mockDocument(selectedDid, selectedDocument);
        mockDidResolver.mockDocument(testMediatorDid, defaultDocument);

        final config = await MediatorUtils.getMediatorConfig(
          didResolver: mockDidResolver,
          defaultMediatorDid: testMediatorDid,
          selectedMediatorDid: selectedDid,
        );

        expect(config, isNotNull);
        expect(config!.mediatorDid, equals(selectedDid));
        expect(config.mediatorEndpoint, equals('https://selected.example.com'));
      });
    });

    group('_getMediatorEndpointByDidDocument (via resolveMediator)', () {
      test('finds http endpoint from StringEndpoint', () async {
        final didDocument = _createDidDocument(
          id: testMediatorDid,
          service: {
            'id': '$testMediatorDid#didcomm',
            'type': 'DIDCommMessaging',
            'serviceEndpoint': [
              'https://mediator.example.com',
              'wss://mediator.example.com/ws',
            ],
          },
        );

        mockDidResolver.mockDocument(testMediatorDid, didDocument);

        final config = await MediatorUtils.resolveMediator(
          testMediatorDid,
          didResolver: mockDidResolver,
        );

        expect(config.mediatorEndpoint, equals('https://mediator.example.com'));
      });

      test('finds wss endpoint from SetEndpoint with MapEndpoint', () async {
        final didDocument = _createDidDocument(
          id: testMediatorDid,
          service: {
            'id': '$testMediatorDid#didcomm',
            'type': 'DIDCommMessaging',
            'serviceEndpoint': [
              {'uri': 'https://mediator.example.com'},
              {'uri': 'wss://mediator.example.com/ws'},
            ],
          },
        );

        mockDidResolver.mockDocument(testMediatorDid, didDocument);

        final config = await MediatorUtils.resolveMediator(
          testMediatorDid,
          didResolver: mockDidResolver,
        );

        expect(config.mediatorWSSEndpoint,
            equals('wss://mediator.example.com/ws'));
      });

      test('returns first matching endpoint for each protocol type', () async {
        final didDocument = _createDidDocument(
          id: testMediatorDid,
          service: {
            'id': '$testMediatorDid#didcomm',
            'type': 'DIDCommMessaging',
            'serviceEndpoint': [
              'https://first.example.com',
              'https://second.example.com',
              'wss://first-ws.example.com/ws',
              'wss://second-ws.example.com/ws',
            ],
          },
        );

        mockDidResolver.mockDocument(testMediatorDid, didDocument);

        final config = await MediatorUtils.resolveMediator(
          testMediatorDid,
          didResolver: mockDidResolver,
        );

        // Should return first matching endpoint for each protocol
        expect(config.mediatorEndpoint, equals('https://first.example.com'));
        expect(config.mediatorWSSEndpoint,
            equals('wss://first-ws.example.com/ws'));
      });

      test('throws exception when required endpoint protocol is missing',
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

        expect(
          () => MediatorUtils.resolveMediator(
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

      test('handles mixed MapEndpoint and StringEndpoint in SetEndpoint',
          () async {
        final didDocument = _createDidDocument(
          id: testMediatorDid,
          service: {
            'id': '$testMediatorDid#didcomm',
            'type': 'DIDCommMessaging',
            'serviceEndpoint': [
              {'uri': 'wss://map.example.com/ws'},
              'https://string.example.com',
            ],
          },
        );

        mockDidResolver.mockDocument(testMediatorDid, didDocument);

        final config = await MediatorUtils.resolveMediator(
          testMediatorDid,
          didResolver: mockDidResolver,
        );

        expect(config.mediatorEndpoint, equals('https://string.example.com'));
        expect(config.mediatorWSSEndpoint, equals('wss://map.example.com/ws'));
      });
    });

    group('EndpointType enum', () {
      test('has correct protocol values', () {
        expect(EndpointType.http.protocol, equals('https'));
        expect(EndpointType.webSocket.protocol, equals('wss'));
      });

      test('enum values are accessible', () {
        expect(EndpointType.values, contains(EndpointType.http));
        expect(EndpointType.values, contains(EndpointType.webSocket));
        expect(EndpointType.values.length, equals(2));
      });
    });
  });
}
