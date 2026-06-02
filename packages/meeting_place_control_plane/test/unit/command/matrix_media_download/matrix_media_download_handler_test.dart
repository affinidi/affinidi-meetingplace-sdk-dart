import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:meeting_place_control_plane/src/api/api_client.dart';
import 'package:meeting_place_control_plane/src/api/control_plane_api_client.dart';
import 'package:meeting_place_control_plane/src/command/matrix_media_download/matrix_media_download.dart';
import 'package:meeting_place_control_plane/src/command/matrix_media_download/matrix_media_download_exception.dart';
import 'package:meeting_place_control_plane/src/command/matrix_media_download/matrix_media_download_handler.dart';
import 'package:meeting_place_control_plane/src/command/matrix_media_download/matrix_media_download_output.dart';
import 'package:meeting_place_control_plane/src/control_plane_sdk_error_code.dart';
import 'package:meeting_place_control_plane/src/loggers/control_plane_sdk_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

class _MockControlPlaneApiClient extends Mock
    implements ControlPlaneApiClient {}

class _MockDefaultApi extends Mock implements DefaultApi {}

class _MockDio extends Mock implements Dio {}

class _MockDidResolver extends Mock implements DidResolver {}

class _MockLogger extends Mock implements ControlPlaneSDKLogger {}

class _FakeMatrixChallenge extends Fake implements MatrixChallenge {}

Future<DidManager> _newDidManager() async {
  final wallet = PersistentWallet(InMemoryKeyStore());
  final didManager = DidKeyManager(wallet: wallet, store: InMemoryDidStore());
  final key = await wallet.generateKey(keyType: KeyType.ed25519);
  await didManager.addVerificationMethod(key.id);
  return didManager;
}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeMatrixChallenge());
  });

  late _MockControlPlaneApiClient apiClient;
  late _MockDefaultApi defaultApi;
  late _MockDio dio;
  late _MockDidResolver didResolver;
  late _MockLogger logger;
  late DidManager senderDidManager;
  late DidManager controlPlaneDidManager;
  late String controlPlaneDid;
  late DidDocument controlPlaneDidDocument;
  final homeserver = Uri.parse('https://matrix.example.com');
  const roomId = '!room:example.com';
  const mxcUri = 'mxc://example.com/media123';
  final mediaBytes = Uint8List.fromList(utf8.encode('binary-media-content'));

  setUp(() async {
    apiClient = _MockControlPlaneApiClient();
    defaultApi = _MockDefaultApi();
    dio = _MockDio();
    didResolver = _MockDidResolver();
    logger = _MockLogger();

    senderDidManager = await _newDidManager();
    controlPlaneDidManager = await _newDidManager();
    controlPlaneDidDocument = await controlPlaneDidManager.getDidDocument();
    controlPlaneDid = controlPlaneDidDocument.id;

    when(() => apiClient.client).thenReturn(defaultApi);
    when(() => apiClient.dio).thenReturn(dio);
    when(
      () => didResolver.resolveDid(controlPlaneDid),
    ).thenAnswer((_) async => controlPlaneDidDocument);
  });

  MatrixMediaDownloadHandler newHandler() => MatrixMediaDownloadHandler(
    apiClient: apiClient,
    didResolver: didResolver,
    controlPlaneDid: controlPlaneDid,
    logger: logger,
  );

  MatrixMediaDownloadCommand newCommand() => MatrixMediaDownloadCommand(
    didManager: senderDidManager,
    homeserver: homeserver,
    roomId: roomId,
    mxcUri: mxcUri,
  );

  Response<T> ok<T>(T data) => Response<T>(
    requestOptions: RequestOptions(path: '/'),
    data: data,
    statusCode: 200,
  );

  void stubChallengeSuccess() {
    when(
      () => defaultApi.matrixChallenge(
        matrixChallenge: any(named: 'matrixChallenge'),
      ),
    ).thenAnswer(
      (_) async => ok(
        (MatrixChallengeOKBuilder()..challenge = 'test-challenge').build(),
      ),
    );
  }

  void stubDownloadUrlSuccess({String url = 'https://cdn.example.com/file'}) {
    when(
      () => dio.post<Map<String, dynamic>>(
        '/v1/matrix/media/download-url',
        data: any(named: 'data'),
        options: any(named: 'options'),
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/v1/matrix/media/download-url'),
        data: {'url': url},
        statusCode: 200,
      ),
    );
  }

  void stubMediaDownloadSuccess(Uint8List bytes) {
    when(
      () => dio.get<dynamic>(any(), options: any(named: 'options')),
    ).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(path: '/file'),
        data: bytes,
        statusCode: 200,
      ),
    );
  }

  group('MatrixMediaDownloadHandler.handle', () {
    test('downloads media successfully and returns bytes', () async {
      stubChallengeSuccess();
      stubDownloadUrlSuccess();
      stubMediaDownloadSuccess(mediaBytes);

      final output = await newHandler().handle(newCommand());

      expect(output, isA<MatrixMediaDownloadCommandOutput>());
      expect(output.bytes, equals(mediaBytes));
    });

    test('sends roomId and mxcUri in download-url request', () async {
      stubChallengeSuccess();
      stubDownloadUrlSuccess();
      stubMediaDownloadSuccess(mediaBytes);

      await newHandler().handle(newCommand());

      final captured =
          verify(
                () => dio.post<Map<String, dynamic>>(
                  '/v1/matrix/media/download-url',
                  data: captureAny(named: 'data'),
                  options: any(named: 'options'),
                ),
              ).captured.single
              as Map<String, dynamic>;

      expect(captured['room_id'], equals(roomId));
      expect(captured['media_uri'], equals(mxcUri));
      expect(captured['homeserver'], equals(homeserver.toString()));
      expect(captured['challenge_response'], isNotEmpty);
    });

    test('throws invalidResponse when challenge returns empty', () async {
      when(
        () => defaultApi.matrixChallenge(
          matrixChallenge: any(named: 'matrixChallenge'),
        ),
      ).thenAnswer((_) async => ok(MatrixChallengeOKBuilder().build()));

      await expectLater(
        newHandler().handle(newCommand()),
        throwsA(
          isA<MatrixMediaDownloadException>().having(
            (e) => e.code,
            'code',
            ControlPlaneSDKErrorCode.matrixMediaDownloadInvalidResponse,
          ),
        ),
      );
    });

    test('wraps matrix challenge failures as generic', () async {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/v1/matrix/challenge'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/v1/matrix/challenge'),
          statusCode: 403,
        ),
      );
      when(
        () => defaultApi.matrixChallenge(
          matrixChallenge: any(named: 'matrixChallenge'),
        ),
      ).thenThrow(dioError);

      await expectLater(
        newHandler().handle(newCommand()),
        throwsA(
          isA<MatrixMediaDownloadException>()
              .having(
                (e) => e.code,
                'code',
                ControlPlaneSDKErrorCode.matrixMediaDownloadGeneric,
              )
              .having((e) => e.innerException, 'innerException', dioError),
        ),
      );
    });

    test(
      'throws invalidResponse when download-url response data is null',
      () async {
        stubChallengeSuccess();
        when(
          () => dio.post<Map<String, dynamic>>(
            '/v1/matrix/media/download-url',
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(
              path: '/v1/matrix/media/download-url',
            ),
            statusCode: 200,
          ),
        );

        await expectLater(
          newHandler().handle(newCommand()),
          throwsA(
            isA<MatrixMediaDownloadException>()
                .having(
                  (e) => e.code,
                  'code',
                  ControlPlaneSDKErrorCode.matrixMediaDownloadInvalidResponse,
                )
                .having((e) => e.message, 'message', 'Response data is null'),
          ),
        );
      },
    );

    test('throws invalidResponse when url is missing from response', () async {
      stubChallengeSuccess();
      when(
        () => dio.post<Map<String, dynamic>>(
          '/v1/matrix/media/download-url',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/v1/matrix/media/download-url'),
          data: <String, dynamic>{},
          statusCode: 200,
        ),
      );

      await expectLater(
        newHandler().handle(newCommand()),
        throwsA(
          isA<MatrixMediaDownloadException>()
              .having(
                (e) => e.code,
                'code',
                ControlPlaneSDKErrorCode.matrixMediaDownloadInvalidResponse,
              )
              .having(
                (e) => e.message,
                'message',
                'Missing or empty url in response',
              ),
        ),
      );
    });

    test('maps 403 DioException to forbidden', () async {
      stubChallengeSuccess();
      when(
        () => dio.post<Map<String, dynamic>>(
          '/v1/matrix/media/download-url',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/v1/matrix/media/download-url'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(
              path: '/v1/matrix/media/download-url',
            ),
            statusCode: 403,
          ),
        ),
      );

      await expectLater(
        newHandler().handle(newCommand()),
        throwsA(
          isA<MatrixMediaDownloadException>().having(
            (e) => e.code,
            'code',
            ControlPlaneSDKErrorCode.matrixMediaDownloadForbidden,
          ),
        ),
      );
    });

    test('maps 404 DioException to notFound', () async {
      stubChallengeSuccess();
      when(
        () => dio.post<Map<String, dynamic>>(
          '/v1/matrix/media/download-url',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/v1/matrix/media/download-url'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(
              path: '/v1/matrix/media/download-url',
            ),
            statusCode: 404,
          ),
        ),
      );

      await expectLater(
        newHandler().handle(newCommand()),
        throwsA(
          isA<MatrixMediaDownloadException>().having(
            (e) => e.code,
            'code',
            ControlPlaneSDKErrorCode.matrixMediaDownloadNotFound,
          ),
        ),
      );
    });

    test('maps 429 DioException to rateLimited with retry-after', () async {
      stubChallengeSuccess();
      when(
        () => dio.post<Map<String, dynamic>>(
          '/v1/matrix/media/download-url',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/v1/matrix/media/download-url'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(
              path: '/v1/matrix/media/download-url',
            ),
            statusCode: 429,
            headers: Headers.fromMap({
              'retry-after': ['60'],
            }),
          ),
        ),
      );

      await expectLater(
        newHandler().handle(newCommand()),
        throwsA(
          isA<MatrixMediaDownloadException>()
              .having(
                (e) => e.code,
                'code',
                ControlPlaneSDKErrorCode.matrixMediaDownloadRateLimited,
              )
              .having((e) => e.retryAfterSeconds, 'retryAfterSeconds', 60),
        ),
      );
    });

    test('maps unknown DioException to generic', () async {
      stubChallengeSuccess();
      when(
        () => dio.post<Map<String, dynamic>>(
          '/v1/matrix/media/download-url',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/v1/matrix/media/download-url'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(
              path: '/v1/matrix/media/download-url',
            ),
            statusCode: 500,
          ),
        ),
      );

      await expectLater(
        newHandler().handle(newCommand()),
        throwsA(
          isA<MatrixMediaDownloadException>().having(
            (e) => e.code,
            'code',
            ControlPlaneSDKErrorCode.matrixMediaDownloadGeneric,
          ),
        ),
      );
    });

    test('wraps non-DioException as generic', () async {
      stubChallengeSuccess();
      when(
        () => dio.post<Map<String, dynamic>>(
          '/v1/matrix/media/download-url',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(Exception('unexpected'));

      await expectLater(
        newHandler().handle(newCommand()),
        throwsA(
          isA<MatrixMediaDownloadException>().having(
            (e) => e.code,
            'code',
            ControlPlaneSDKErrorCode.matrixMediaDownloadGeneric,
          ),
        ),
      );
    });

    test('converts List<int> response to Uint8List', () async {
      stubChallengeSuccess();
      stubDownloadUrlSuccess();
      when(
        () => dio.get<dynamic>(any(), options: any(named: 'options')),
      ).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(path: '/file'),
          data: <int>[72, 101, 108, 108, 111],
          statusCode: 200,
        ),
      );

      final output = await newHandler().handle(newCommand());
      expect(
        output.bytes,
        equals(Uint8List.fromList([72, 101, 108, 108, 111])),
      );
    });

    test('throws invalidResponse when media response is not bytes', () async {
      stubChallengeSuccess();
      stubDownloadUrlSuccess();
      when(
        () => dio.get<dynamic>(any(), options: any(named: 'options')),
      ).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(path: '/file'),
          data: 'not bytes',
          statusCode: 200,
        ),
      );

      await expectLater(
        newHandler().handle(newCommand()),
        throwsA(
          isA<MatrixMediaDownloadException>().having(
            (e) => e.code,
            'code',
            ControlPlaneSDKErrorCode.matrixMediaDownloadInvalidResponse,
          ),
        ),
      );
    });
  });
}
