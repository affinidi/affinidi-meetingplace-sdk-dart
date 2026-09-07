import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:test/test.dart';

import 'mocks.dart';

void main() {
  late RecordingMeetingPlaceControlPlaneSDK sdk;

  setUp(() {
    sdk = RecordingMeetingPlaceControlPlaneSDK();
  });

  group('When using miscellaneous facade methods', () {
    group('and registering a device', () {
      test('it executes the matching command and returns its result', () async {
        final output = RegisterDeviceResult(success: true);
        sdk.stubbedResult = output;

        final result = await sdk.registerDevice(
          deviceToken: 'device-token',
          platformType: PlatformType.pushNotification,
        );

        expect(result, same(output));
        final command = sdk.lastCommand as RegisterDeviceCommand;
        expect(command.deviceToken, 'device-token');
        expect(command.platformType, PlatformType.pushNotification);
      });
    });

    group('and getting a Matrix token', () {
      test('it executes the matching command and returns its result', () async {
        final didManager = MockDidManager();
        final homeserver = Uri.parse('https://matrix.example.com');
        final output = GetMatrixTokenResult(
          token: MatrixLoginToken(
            iss: 'issuer',
            sub: 'subject',
            aud: 'audience',
            exp: '2000000000',
            iat: '1900000000',
            jti: 'token-id',
            rawJwt: 'header.payload.signature',
          ),
        );
        sdk.stubbedResult = output;

        final result = await sdk.getMatrixToken(
          didManager: didManager,
          homeserver: homeserver,
        );

        expect(result, same(output));
        final command = sdk.lastCommand as MatrixTokenCommand;
        expect(command.didManager, same(didManager));
        expect(command.homeserver, same(homeserver));
      });
    });

    group('and uploading a did:web DID Document', () {
      test('it executes the matching command and returns its result', () async {
        final didDocument = <String, dynamic>{
          'id': 'did:web:example.com:user:alice',
        };
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
        final output = UploadDidWebDocumentResult(
          record: DidDocumentHostingRecord(
            did: 'did:web:example.com:user:alice',
            segment: 'alice',
            didDocUrl: 'https://example.com/user/alice/did.json',
          ),
        );
        sdk.stubbedResult = output;

        final result = await sdk.uploadDidWebDocument(
          didDocument: didDocument,
          controlProof: controlProof,
          proof: proof,
        );

        expect(result, same(output));
        final command = sdk.lastCommand as UploadDidWebDocumentCommand;
        expect(command.didDocument, same(didDocument));
        expect(command.controlProof, same(controlProof));
        expect(command.proof, same(proof));
      });
    });
  });
}
