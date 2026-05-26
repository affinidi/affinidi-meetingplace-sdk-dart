import 'package:dio/dio.dart';
import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:meeting_place_control_plane/src/api/auth_credentials.dart';
import 'package:meeting_place_control_plane/src/api/control_plane_api_client.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockControlPlaneSDK extends Mock implements ControlPlaneSDK {}

class FakeAuthenticateCommand extends Fake implements AuthenticateCommand {}

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

    final dio = Dio(BaseOptions(baseUrl: 'https://example.com'));
    Map<String, dynamic>? capturedData;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedData = Map<String, dynamic>.from(
            options.data as Map<String, dynamic>,
          );
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: {
                'did': 'did:web:example.com:user:alice',
                'segment': 'alice',
                'didDocUrl': 'https://example.com/user/alice/did.json',
              },
            ),
          );
        },
      ),
    );

    final client = ControlPlaneApiClient.forTesting(
      dio: dio,
      basePath: 'https://example.com',
      controlPlaneSDK: mockControlPlaneSDK,
      controlPlaneDid: controlPlaneDid,
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

    await client.uploadDidDocument(
      {'id': 'did:web:example.com:user:alice'},
      controlProof: controlProof,
      proof: proof,
    );

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
