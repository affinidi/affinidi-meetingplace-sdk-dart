import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:meeting_place_control_plane/src/api/auth_credentials.dart';
import 'package:meeting_place_control_plane/src/api/control_plane_api_client.dart';
import 'package:meeting_place_control_plane/src/api/control_plane_api_client_options.dart';
import 'package:meeting_place_control_plane/src/api/did_web_document_api.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

import 'mocks.dart';

DidDocument _didDocument(String did, Uri apiBaseUri) => DidDocument.fromJson({
  '@context': ['https://www.w3.org/ns/did/v1'],
  'id': did,
  'verificationMethod': const <Object>[],
  'authentication': const <Object>[],
  'service': [
    {
      'id': '$did#control-plane',
      'type': 'RestAPI',
      'serviceEndpoint': apiBaseUri.toString(),
    },
  ],
});

void main() {
  const controlPlaneDid = 'did:web:example.com';

  setUpAll(() {
    registerFallbackValue(FakeAuthenticateCommand());
  });

  test('uploadDidDocument sends proof objects in the request body', () async {
    final mockControlPlaneSDK = MockControlPlaneSDK();
    when(
      () => mockControlPlaneSDK.execute(any<AuthenticateCommand>()),
    ).thenAnswer(
      (_) async => AuthenticateCommandOutput(
        credentials: AuthCredentials(
          accessToken: 'access-token',
          refreshToken: 'refresh-token',
          accessExpiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
          refreshExpiresAt: DateTime.now().toUtc().add(const Duration(days: 1)),
        ),
      ),
    );
    Map<String, dynamic>? capturedData;
    final requestHandled = Completer<void>();
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async {
      await server.close(force: true);
    });

    server.listen((request) async {
      try {
        expect(request.method, 'POST');
        expect(request.uri.path, '/v1/did-document/upload');

        final body = await utf8.decoder.bind(request).join();
        final decodedBody = jsonDecode(body);
        if (decodedBody is! Map<String, dynamic>) {
          fail('Expected JSON object body, got ${decodedBody.runtimeType}');
        }
        capturedData = Map<String, dynamic>.from(decodedBody);

        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode({
              'did': 'did:web:example.com:user:alice',
              'segment': 'alice',
              'didDocUrl': 'https://example.com/user/alice/did.json',
            }),
          );
        await request.response.close();
        requestHandled.complete();
      } catch (error, stackTrace) {
        if (!requestHandled.isCompleted) {
          requestHandled.completeError(error, stackTrace);
        }
        rethrow;
      }
    });

    final apiBaseUri = Uri.parse(
      'http://${server.address.address}:${server.port}/v1',
    );

    final client = await ControlPlaneApiClient.init(
      options: ControlPlaneApiClientOptions(controlPlaneDid: controlPlaneDid),
      controlPlaneSDK: mockControlPlaneSDK,
      didResolver: FakeDidResolver({
        controlPlaneDid: _didDocument(controlPlaneDid, apiBaseUri),
      }),
    );

    final controlProof = DidWebProof(
      type: 'JsonWebSignature2020',
      created: '2026-01-01T00:00:00Z',
      verificationMethod: 'did:key:zAlice123#control-1',
      proofPurpose: 'authentication',
      jws: 'control-jws',
    );
    final proof = DidWebProof(
      type: 'JsonWebSignature2020',
      created: '2026-01-01T00:00:00Z',
      verificationMethod: 'did:web:example.com:user:alice#auth',
      proofPurpose: 'authentication',
      jws: 'proof-jws',
    );

    await DidWebDocumentApi(dio: client.dio).uploadDidDocument(
      {'id': 'did:web:example.com:user:alice'},
      controlProof: controlProof,
      proof: proof,
    );
    await requestHandled.future;

    expect(capturedData, isNotNull);
    expect(
      capturedData!['controlProof'],
      equals({
        'type': 'JsonWebSignature2020',
        'created': '2026-01-01T00:00:00Z',
        'verificationMethod': 'did:key:zAlice123#control-1',
        'proofPurpose': 'authentication',
        'jws': 'control-jws',
      }),
    );
    expect(
      capturedData!['proof'],
      equals({
        'type': 'JsonWebSignature2020',
        'created': '2026-01-01T00:00:00Z',
        'verificationMethod': 'did:web:example.com:user:alice#auth',
        'proofPurpose': 'authentication',
        'jws': 'proof-jws',
      }),
    );
  });
}
