import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart' show OpenIdCredentials;
import 'package:meeting_place_matrix_livekit/src/exceptions/meeting_place_livekit_call_exception.dart';
import 'package:meeting_place_matrix_livekit/src/services/sfu_token_service.dart';
import 'package:mocktail/mocktail.dart';

import '../mocks/mocks.dart';

OpenIdCredentials _credentials() => OpenIdCredentials(
  accessToken: 'matrix-openid-token',
  expiresIn: 3600,
  matrixServerName: 'matrix.example.com',
  tokenType: 'Bearer',
);

Response<Map<String, dynamic>> _response(
  Map<String, dynamic>? data, {
  int statusCode = 200,
}) => Response<Map<String, dynamic>>(
  requestOptions: RequestOptions(path: '/sfu/get'),
  statusCode: statusCode,
  data: data,
);

void main() {
  setUpAll(() {
    registerFallbackValue(Uri.parse('https://livekit.example.com/sfu/get'));
    registerFallbackValue(Options());
  });

  late MockDio dio;
  late MockMeetingPlaceCoreSDKLogger logger;
  late SfuTokenService service;

  setUp(() {
    dio = MockDio();
    logger = MockMeetingPlaceCoreSDKLogger();
    service = SfuTokenService(
      serviceUrl: Uri.parse('https://livekit.example.com'),
      dio: dio,
      logger: logger,
    );
  });

  void stubPost(Response<Map<String, dynamic>> response) {
    when(
      () => dio.postUri<Map<String, dynamic>>(
        any<Uri>(),
        data: any<dynamic>(named: 'data'),
        options: any<Options>(named: 'options'),
      ),
    ).thenAnswer((_) async => response);
  }

  group('fetchToken success', () {
    test('returns the jwt and url from the response body', () async {
      stubPost(
        _response({'jwt': 'livekit-jwt', 'url': 'wss://sfu.example.com'}),
      );

      final result = await service.fetchToken(
        roomName: 'room-1',
        openIdCredentials: _credentials(),
      );

      expect(result.token, 'livekit-jwt');
      expect(result.url, 'wss://sfu.example.com');
    });

    test('returns a null url when the response omits it', () async {
      stubPost(_response({'jwt': 'livekit-jwt'}));

      final result = await service.fetchToken(
        roomName: 'room-1',
        openIdCredentials: _credentials(),
      );

      expect(result.token, 'livekit-jwt');
      expect(result.url, isNull);
    });

    test('posts to the /sfu/get path on the configured service url', () async {
      stubPost(_response({'jwt': 'livekit-jwt'}));

      await service.fetchToken(
        roomName: 'room-1',
        openIdCredentials: _credentials(),
      );

      final uri =
          verify(
                () => dio.postUri<Map<String, dynamic>>(
                  captureAny<Uri>(),
                  data: any<dynamic>(named: 'data'),
                  options: any<Options>(named: 'options'),
                ),
              ).captured.single
              as Uri;
      expect(uri.toString(), 'https://livekit.example.com/sfu/get');
    });

    test('includes device_id in the request body when provided', () async {
      stubPost(_response({'jwt': 'livekit-jwt'}));

      await service.fetchToken(
        roomName: 'room-1',
        openIdCredentials: _credentials(),
        deviceId: 'DEVICE123',
      );

      final body =
          verify(
                () => dio.postUri<Map<String, dynamic>>(
                  any<Uri>(),
                  data: captureAny<dynamic>(named: 'data'),
                  options: any<Options>(named: 'options'),
                ),
              ).captured.single
              as Map<String, dynamic>;
      expect(body['device_id'], 'DEVICE123');
      expect(body['room'], 'room-1');
    });

    test('omits device_id from the request body when empty', () async {
      stubPost(_response({'jwt': 'livekit-jwt'}));

      await service.fetchToken(
        roomName: 'room-1',
        openIdCredentials: _credentials(),
        deviceId: '',
      );

      final body =
          verify(
                () => dio.postUri<Map<String, dynamic>>(
                  any<Uri>(),
                  data: captureAny<dynamic>(named: 'data'),
                  options: any<Options>(named: 'options'),
                ),
              ).captured.single
              as Map<String, dynamic>;
      expect(body.containsKey('device_id'), isFalse);
    });
  });

  group('fetchToken failure', () {
    test('throws when the response body is null', () async {
      stubPost(_response(null));

      await expectLater(
        service.fetchToken(
          roomName: 'room-1',
          openIdCredentials: _credentials(),
        ),
        throwsA(isA<MeetingPlaceLiveKitCallOperationException>()),
      );
    });

    test('throws when the jwt field is missing', () async {
      stubPost(_response({'url': 'wss://sfu.example.com'}));

      await expectLater(
        service.fetchToken(
          roomName: 'room-1',
          openIdCredentials: _credentials(),
        ),
        throwsA(isA<MeetingPlaceLiveKitCallOperationException>()),
      );
    });

    test('throws when the jwt field is empty', () async {
      stubPost(_response({'jwt': ''}));

      await expectLater(
        service.fetchToken(
          roomName: 'room-1',
          openIdCredentials: _credentials(),
        ),
        throwsA(isA<MeetingPlaceLiveKitCallOperationException>()),
      );
    });

    test('wraps a DioException as an operation exception', () async {
      when(
        () => dio.postUri<Map<String, dynamic>>(
          any<Uri>(),
          data: any<dynamic>(named: 'data'),
          options: any<Options>(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/sfu/get'),
          message: 'connection refused',
        ),
      );

      await expectLater(
        service.fetchToken(
          roomName: 'room-1',
          openIdCredentials: _credentials(),
        ),
        throwsA(
          isA<MeetingPlaceLiveKitCallOperationException>().having(
            (e) => e.innerException,
            'innerException',
            isA<DioException>(),
          ),
        ),
      );
    });
  });
}
