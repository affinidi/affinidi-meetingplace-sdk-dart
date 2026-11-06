import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:meeting_place_control_plane/src/api/api_client.dart';
import 'package:meeting_place_control_plane/src/api/control_plane_api_client.dart';
import 'package:meeting_place_control_plane/src/core/didcomm/didcomm_challenge_response.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

class _MockControlPlaneApiClient extends Mock
    implements ControlPlaneApiClient {}

class _MockDefaultApi extends Mock implements DefaultApi {}

class _MockDidResolver extends Mock implements DidResolver {}

class _FakeDidChallenge extends Fake implements DidChallenge {}

class _FakeMatrixChallenge extends Fake implements MatrixChallenge {}

Future<DidManager> _newDidManager() async {
  final wallet = PersistentWallet(InMemoryKeyStore());
  final didManager = DidKeyManager(wallet: wallet, store: InMemoryDidStore());
  final key = await wallet.generateKey(keyType: KeyType.ed25519);
  await didManager.addVerificationMethod(key.id);
  return didManager;
}

/// A did:web agreeing keys over both X25519, from its Ed25519 key, and
/// P-256, as a new permanent channel DID and the hosted control plane do.
Future<DidManager> _newTwoCurveDidManager(String host) async {
  final wallet = PersistentWallet(InMemoryKeyStore());
  final didManager = DidWebManager(
    wallet: wallet,
    store: InMemoryDidStore(),
    domain: Uri.parse('https://$host'),
  );
  final ed25519 = await wallet.generateKey(keyType: KeyType.ed25519);
  await didManager.addVerificationMethod(
    ed25519.id,
    relationships: {
      VerificationRelationship.authentication,
      VerificationRelationship.keyAgreement,
    },
  );
  final p256 = await wallet.generateKey(keyType: KeyType.p256);
  await didManager.addVerificationMethod(
    p256.id,
    relationships: {VerificationRelationship.keyAgreement},
  );
  return didManager;
}

Response<T> _ok<T>(T data) => Response<T>(
  requestOptions: RequestOptions(path: '/'),
  data: data,
  statusCode: 200,
);

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeDidChallenge());
    registerFallbackValue(_FakeMatrixChallenge());
  });

  late _MockControlPlaneApiClient apiClient;
  late _MockDefaultApi defaultApi;
  late _MockDidResolver didResolver;
  late DidManager senderDidManager;
  late DidManager recipientDidManager;
  late String senderDid;
  late DidDocument recipientDidDocument;

  setUp(() async {
    apiClient = _MockControlPlaneApiClient();
    defaultApi = _MockDefaultApi();
    didResolver = _MockDidResolver();

    senderDidManager = await _newDidManager();
    recipientDidManager = await _newDidManager();
    senderDid = (await senderDidManager.getDidDocument()).id;
    recipientDidDocument = await recipientDidManager.getDidDocument();

    when(() => apiClient.client).thenReturn(defaultApi);
    when(
      () => didResolver.resolveDid(recipientDidDocument.id),
    ).thenAnswer((_) async => recipientDidDocument);
  });

  group('DidCommChallengeResponse', () {
    group('build', () {
      test(
        'returns sender DID and base64-encoded DIDComm payload on success',
        () async {
          when(
            () => defaultApi.didChallenge(
              didChallenge: any(named: 'didChallenge'),
            ),
          ).thenAnswer(
            (_) async => _ok(
              (DidChallengeOKBuilder()..challenge = 'a-challenge').build(),
            ),
          );

          final result = await DidCommChallengeResponse.build(
            apiClient: apiClient,
            didManager: senderDidManager,
            didResolver: didResolver,
            recipientDid: recipientDidDocument.id,
          );

          expect(result.senderDid, equals(senderDid));
          final decoded =
              jsonDecode(utf8.decode(base64Decode(result.challengeResponse)))
                  as Map<String, dynamic>;
          // Encrypted DIDComm envelope has these JWE fields.
          expect(decoded, contains('ciphertext'));
          expect(decoded, contains('protected'));
          expect(decoded, contains('recipients'));

          final captured =
              verify(
                    () => defaultApi.didChallenge(
                      didChallenge: captureAny(named: 'didChallenge'),
                    ),
                  ).captured.single
                  as DidChallenge;
          expect(captured.did, equals(senderDid));
          verifyNever(
            () => defaultApi.matrixChallenge(
              matrixChallenge: any(named: 'matrixChallenge'),
            ),
          );
          verify(
            () => didResolver.resolveDid(recipientDidDocument.id),
          ).called(1);
        },
      );

      test(
        'throws StateError when challenge is empty and no callback given',
        () async {
          when(
            () => defaultApi.didChallenge(
              didChallenge: any(named: 'didChallenge'),
            ),
          ).thenAnswer(
            (_) async => _ok((DidChallengeOKBuilder()..challenge = '').build()),
          );

          expect(
            () => DidCommChallengeResponse.build(
              apiClient: apiClient,
              didManager: senderDidManager,
              didResolver: didResolver,
              recipientDid: recipientDidDocument.id,
            ),
            throwsA(
              isA<StateError>().having(
                (e) => e.message,
                'message',
                'Empty challenge returned from challenge endpoint',
              ),
            ),
          );
        },
      );

      test('throws StateError when challenge is whitespace-only', () async {
        when(
          () =>
              defaultApi.didChallenge(didChallenge: any(named: 'didChallenge')),
        ).thenAnswer(
          (_) async =>
              _ok((DidChallengeOKBuilder()..challenge = '   ').build()),
        );

        expect(
          () => DidCommChallengeResponse.build(
            apiClient: apiClient,
            didManager: senderDidManager,
            didResolver: didResolver,
            recipientDid: recipientDidDocument.id,
          ),
          throwsA(isA<StateError>()),
        );
      });

      test(
        'invokes onEmptyChallenge with sender DID and throws its exception',
        () async {
          when(
            () => defaultApi.didChallenge(
              didChallenge: any(named: 'didChallenge'),
            ),
          ).thenAnswer((_) async => _ok(DidChallengeOKBuilder().build()));

          String? receivedDid;
          Exception buildException(String did) {
            receivedDid = did;
            return _CustomEmptyChallengeException(did);
          }

          await expectLater(
            DidCommChallengeResponse.build(
              apiClient: apiClient,
              didManager: senderDidManager,
              didResolver: didResolver,
              recipientDid: recipientDidDocument.id,
              onEmptyChallenge: buildException,
            ),
            throwsA(isA<_CustomEmptyChallengeException>()),
          );
          expect(receivedDid, equals(senderDid));
        },
      );
    });

    group('buildForMatrix', () {
      test(
        'uses matrix challenge endpoint and returns encoded payload',
        () async {
          when(
            () => defaultApi.matrixChallenge(
              matrixChallenge: any(named: 'matrixChallenge'),
            ),
          ).thenAnswer(
            (_) async => _ok(
              (MatrixChallengeOKBuilder()..challenge = 'matrix-challenge')
                  .build(),
            ),
          );

          final result = await DidCommChallengeResponse.buildForMatrix(
            apiClient: apiClient,
            didManager: senderDidManager,
            didResolver: didResolver,
            recipientDid: recipientDidDocument.id,
          );

          expect(result.senderDid, equals(senderDid));
          final decoded =
              jsonDecode(utf8.decode(base64Decode(result.challengeResponse)))
                  as Map<String, dynamic>;
          expect(decoded, contains('ciphertext'));

          final captured =
              verify(
                    () => defaultApi.matrixChallenge(
                      matrixChallenge: captureAny(named: 'matrixChallenge'),
                    ),
                  ).captured.single
                  as MatrixChallenge;
          expect(captured.did, equals(senderDid));
          verifyNever(
            () => defaultApi.didChallenge(
              didChallenge: any(named: 'didChallenge'),
            ),
          );
        },
      );

      test('seals with a P-256 key when both sides also agree over '
          'X25519', () async {
        final sender = await _newTwoCurveDidManager('member.example');
        final senderDocument = await sender.getDidDocument();
        final controlPlane = await (await _newTwoCurveDidManager(
          'control-plane.example',
        )).getDidDocument();
        when(
          () => didResolver.resolveDid(controlPlane.id),
        ).thenAnswer((_) async => controlPlane);
        when(
          () => defaultApi.matrixChallenge(
            matrixChallenge: any(named: 'matrixChallenge'),
          ),
        ).thenAnswer(
          (_) async => _ok(
            (MatrixChallengeOKBuilder()..challenge = 'matrix-challenge')
                .build(),
          ),
        );

        final result = await DidCommChallengeResponse.buildForMatrix(
          apiClient: apiClient,
          didManager: sender,
          didResolver: didResolver,
          recipientDid: controlPlane.id,
        );

        final envelope =
            jsonDecode(utf8.decode(base64Decode(result.challengeResponse)))
                as Map<String, dynamic>;
        final header =
            jsonDecode(
                  utf8.decode(
                    base64Url.decode(
                      base64Url.normalize(envelope['protected'] as String),
                    ),
                  ),
                )
                as Map<String, dynamic>;
        expect(header['skid'], senderDocument.keyAgreement.last.id);
        expect((header['epk'] as Map<String, dynamic>)['crv'], 'P-256');
      });

      test('invokes onEmptyChallenge for empty matrix challenge', () async {
        when(
          () => defaultApi.matrixChallenge(
            matrixChallenge: any(named: 'matrixChallenge'),
          ),
        ).thenAnswer((_) async => _ok(MatrixChallengeOKBuilder().build()));

        await expectLater(
          DidCommChallengeResponse.buildForMatrix(
            apiClient: apiClient,
            didManager: senderDidManager,
            didResolver: didResolver,
            recipientDid: recipientDidDocument.id,
            onEmptyChallenge: _CustomEmptyChallengeException.new,
          ),
          throwsA(isA<_CustomEmptyChallengeException>()),
        );
      });
    });
  });
}

class _CustomEmptyChallengeException implements Exception {
  _CustomEmptyChallengeException(this.senderDid);
  final String senderDid;
}
