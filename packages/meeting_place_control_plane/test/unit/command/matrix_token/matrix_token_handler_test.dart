import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:meeting_place_control_plane/src/api/api_client.dart';
import 'package:meeting_place_control_plane/src/api/control_plane_api_client.dart';
import 'package:meeting_place_control_plane/src/command/matrix_token/matrix_token_handler.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

class _MockControlPlaneApiClient extends Mock
    implements ControlPlaneApiClient {}

class _MockDefaultApi extends Mock implements DefaultApi {}

class _MockDidResolver extends Mock implements DidResolver {}

class _MockLogger extends Mock implements ControlPlaneSDKLogger {}

class _FakeMatrixChallenge extends Fake implements MatrixChallenge {}

class _FakeMatrixToken extends Fake implements MatrixToken {}

Future<DidManager> _newDidManager() async {
  final wallet = PersistentWallet(InMemoryKeyStore());
  final didManager = DidKeyManager(wallet: wallet, store: InMemoryDidStore());
  final key = await wallet.generateKey(keyType: KeyType.ed25519);
  await didManager.addVerificationMethod(key.id);
  return didManager;
}

Response<T> _ok<T>(T data) => Response<T>(
  requestOptions: RequestOptions(path: '/'),
  data: data,
  statusCode: 200,
);

String _makeJwt({
  String iss = 'control-plane',
  String sub = 'sender',
  String aud = 'matrix-homeserver',
  int exp = 1900000000,
  int iat = 1800000000,
  String jti = 'jti-1',
}) {
  String b64(Map<String, dynamic> m) =>
      base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  final header = b64({'alg': 'none', 'typ': 'JWT'});
  final payload = b64({
    'iss': iss,
    'sub': sub,
    'aud': aud,
    'exp': exp,
    'iat': iat,
    'jti': jti,
  });
  return '$header.$payload.sig';
}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeMatrixChallenge());
    registerFallbackValue(_FakeMatrixToken());
  });

  late _MockControlPlaneApiClient apiClient;
  late _MockDefaultApi defaultApi;
  late _MockDidResolver didResolver;
  late _MockLogger logger;
  late DidManager senderDidManager;
  late DidManager controlPlaneDidManager;
  late String senderDid;
  late String controlPlaneDid;
  late DidDocument controlPlaneDidDocument;
  final homeserver = Uri.parse('https://matrix.example.com');

  setUp(() async {
    apiClient = _MockControlPlaneApiClient();
    defaultApi = _MockDefaultApi();
    didResolver = _MockDidResolver();
    logger = _MockLogger();

    senderDidManager = await _newDidManager();
    controlPlaneDidManager = await _newDidManager();
    senderDid = (await senderDidManager.getDidDocument()).id;
    controlPlaneDidDocument = await controlPlaneDidManager.getDidDocument();
    controlPlaneDid = controlPlaneDidDocument.id;

    when(() => apiClient.client).thenReturn(defaultApi);
    when(
      () => didResolver.resolveDid(controlPlaneDid),
    ).thenAnswer((_) async => controlPlaneDidDocument);
    when(
      () => defaultApi.matrixChallenge(
        matrixChallenge: any(named: 'matrixChallenge'),
      ),
    ).thenAnswer(
      (_) async =>
          _ok((MatrixChallengeOKBuilder()..challenge = 'a-challenge').build()),
    );
  });

  MatrixTokenHandler newHandler() => MatrixTokenHandler(
    apiClient: apiClient,
    didResolver: didResolver,
    controlPlaneDid: controlPlaneDid,
    logger: logger,
  );

  MatrixTokenCommand newCommand() =>
      MatrixTokenCommand(didManager: senderDidManager, homeserver: homeserver);

  group('MatrixTokenHandler.handle', () {
    test(
      'returns parsed token and sends homeserver + challenge response',
      () async {
        final jwt = _makeJwt(sub: senderDid);
        when(
          () => defaultApi.matrixToken(matrixToken: any(named: 'matrixToken')),
        ).thenAnswer(
          (_) async => _ok((MatrixTokenOKBuilder()..token = jwt).build()),
        );

        final output = await newHandler().handle(newCommand());

        expect(output.token.toJwt(), equals(jwt));
        expect(output.token.sub, equals(senderDid));
        expect(output.token.aud, equals('matrix-homeserver'));

        final captured =
            verify(
                  () => defaultApi.matrixToken(
                    matrixToken: captureAny(named: 'matrixToken'),
                  ),
                ).captured.single
                as MatrixToken;
        expect(captured.homeserver, equals(homeserver.toString()));
        final challengeResponse = captured.challengeResponse!;
        expect(challengeResponse, isNotEmpty);
        // Challenge response is the base64-encoded JWE envelope.
        final decoded =
            jsonDecode(utf8.decode(base64Decode(challengeResponse)))
                as Map<String, dynamic>;
        expect(decoded, contains('ciphertext'));
      },
    );

    test(
      'throws invalidResponse when matrixChallenge returns empty challenge',
      () async {
        when(
          () => defaultApi.matrixChallenge(
            matrixChallenge: any(named: 'matrixChallenge'),
          ),
        ).thenAnswer((_) async => _ok(MatrixChallengeOKBuilder().build()));

        await expectLater(
          newHandler().handle(newCommand()),
          throwsA(
            isA<MatrixTokenException>()
                .having(
                  (e) => e.code,
                  'code',
                  ControlPlaneSDKErrorCode.matrixTokenInvalidResponse,
                )
                .having(
                  (e) => e.message,
                  'message',
                  'Empty challenge returned from matrixChallenge',
                ),
          ),
        );
        verifyNever(
          () => defaultApi.matrixToken(matrixToken: any(named: 'matrixToken')),
        );
      },
    );

    test(
      'throws invalidResponse when matrixToken response data is null',
      () async {
        when(
          () => defaultApi.matrixToken(matrixToken: any(named: 'matrixToken')),
        ).thenAnswer(
          (_) async => Response<MatrixTokenOK>(
            requestOptions: RequestOptions(path: '/'),
            statusCode: 200,
          ),
        );

        await expectLater(
          newHandler().handle(newCommand()),
          throwsA(
            isA<MatrixTokenException>()
                .having(
                  (e) => e.code,
                  'code',
                  ControlPlaneSDKErrorCode.matrixTokenInvalidResponse,
                )
                .having((e) => e.message, 'message', 'Response data is null'),
          ),
        );
      },
    );

    test('throws invalidResponse when token is missing', () async {
      when(
        () => defaultApi.matrixToken(matrixToken: any(named: 'matrixToken')),
      ).thenAnswer((_) async => _ok(MatrixTokenOKBuilder().build()));

      await expectLater(
        newHandler().handle(newCommand()),
        throwsA(
          isA<MatrixTokenException>()
              .having(
                (e) => e.code,
                'code',
                ControlPlaneSDKErrorCode.matrixTokenInvalidResponse,
              )
              .having(
                (e) => e.message,
                'message',
                'Missing or empty token in response',
              ),
        ),
      );
    });

    test('throws invalidResponse when token is whitespace-only', () async {
      when(
        () => defaultApi.matrixToken(matrixToken: any(named: 'matrixToken')),
      ).thenAnswer(
        (_) async => _ok((MatrixTokenOKBuilder()..token = '   ').build()),
      );

      await expectLater(
        newHandler().handle(newCommand()),
        throwsA(
          isA<MatrixTokenException>().having(
            (e) => e.code,
            'code',
            ControlPlaneSDKErrorCode.matrixTokenInvalidResponse,
          ),
        ),
      );
    });

    test('wraps unexpected errors from matrixToken as generic '
        'MatrixTokenException', () async {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/v1/matrix/token'),
        type: DioExceptionType.badResponse,
        message: 'boom',
      );
      when(
        () => defaultApi.matrixToken(matrixToken: any(named: 'matrixToken')),
      ).thenThrow(dioError);

      await expectLater(
        newHandler().handle(newCommand()),
        throwsA(
          isA<MatrixTokenException>()
              .having(
                (e) => e.code,
                'code',
                ControlPlaneSDKErrorCode.matrixTokenGeneric,
              )
              .having((e) => e.innerException, 'innerException', dioError)
              .having(
                (e) => e.message,
                'message',
                'Failed to fetch Matrix login token',
              ),
        ),
      );
    });

    test(
      'preserves MatrixTokenException type when token JWT is malformed',
      () async {
        // fromJwt throws FormatException on a non-3-part JWT; that gets wrapped
        // as generic.
        when(
          () => defaultApi.matrixToken(matrixToken: any(named: 'matrixToken')),
        ).thenAnswer(
          (_) async =>
              _ok((MatrixTokenOKBuilder()..token = 'not-a-jwt').build()),
        );

        await expectLater(
          newHandler().handle(newCommand()),
          throwsA(
            isA<MatrixTokenException>().having(
              (e) => e.code,
              'code',
              ControlPlaneSDKErrorCode.matrixTokenGeneric,
            ),
          ),
        );
      },
    );
  });
}
