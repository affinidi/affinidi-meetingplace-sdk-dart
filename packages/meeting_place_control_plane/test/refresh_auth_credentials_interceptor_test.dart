import 'dart:io';
import 'package:dio/dio.dart';
import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:meeting_place_control_plane/src/api/auth_credentials.dart';
import 'package:meeting_place_control_plane/src/api/refresh_auth_credentials_interceptor.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockDio extends Mock implements Dio {}

class MockControlPlaneSDK extends Mock implements ControlPlaneSDK {}

class MockRequestInterceptorHandler extends Mock
    implements RequestInterceptorHandler {}

class MockErrorInterceptorHandler extends Mock
    implements ErrorInterceptorHandler {}

class FakeRequestOptions extends Fake implements RequestOptions {}

class FakeResponse extends Fake implements Response {}

class FakeAuthenticateCommand extends Fake implements AuthenticateCommand {}

class FakeDioException extends Fake implements DioException {}

void main() {
  late RefreshAuthCredentialsInterceptor interceptor;
  late MockDio mockDio;
  late MockControlPlaneSDK mockControlPlaneSDK;
  late MockRequestInterceptorHandler mockRequestHandler;
  late MockErrorInterceptorHandler mockErrorHandler;

  const controlPlaneDid = 'did:example:123';

  setUpAll(() {
    registerFallbackValue(FakeRequestOptions());
    registerFallbackValue(FakeResponse());
    registerFallbackValue(FakeAuthenticateCommand());
    registerFallbackValue(FakeDioException());
  });

  setUp(() {
    mockDio = MockDio();
    mockControlPlaneSDK = MockControlPlaneSDK();
    mockRequestHandler = MockRequestInterceptorHandler();
    mockErrorHandler = MockErrorInterceptorHandler();

    interceptor = RefreshAuthCredentialsInterceptor(
      dio: mockDio,
      controlPlaneSDK: mockControlPlaneSDK,
      controlPlaneDid: controlPlaneDid,
    );
  });

  group('RefreshAuthCredentialsInterceptor - onRequest', () {
    test('should skip authentication for public endpoints', () async {
      final requestOptions = RequestOptions(path: '/public', extra: {});
      when(() => mockRequestHandler.next(any())).thenReturn(null);

      await interceptor.onRequest(requestOptions, mockRequestHandler);

      verify(() => mockRequestHandler.next(requestOptions)).called(1);
      verifyNever(() => mockControlPlaneSDK.execute(any()));
    });

    test('should skip authentication when secure flag is empty', () async {
      final requestOptions = RequestOptions(
        path: '/test',
        extra: {'secure': ''},
      );

      when(() => mockRequestHandler.next(any())).thenReturn(null);
      await interceptor.onRequest(requestOptions, mockRequestHandler);

      verify(() => mockRequestHandler.next(requestOptions)).called(1);
      verifyNever(() => mockControlPlaneSDK.execute(any()));
    });

    test('should refresh token for secure endpoints', () async {
      final requestOptions = RequestOptions(
        path: '/secure',
        extra: {'secure': 'true'},
      );

      final authCredentials = AuthCredentials(
        accessToken: 'new-access-token',
        refreshToken: 'new-refresh-token',
        accessExpiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
        refreshExpiresAt: DateTime.now().toUtc().add(const Duration(days: 30)),
      );

      final authResult = AuthenticateCommandOutput(
        credentials: authCredentials,
      );

      when(
        () => mockControlPlaneSDK.execute(any<AuthenticateCommand>()),
      ).thenAnswer((_) async => authResult);
      when(() => mockRequestHandler.next(any())).thenReturn(null);

      await interceptor.onRequest(requestOptions, mockRequestHandler);

      expect(
        requestOptions.headers['Authorization'],
        equals('Bearer new-access-token'),
      );

      verify(
        () => mockControlPlaneSDK.execute(any<AuthenticateCommand>()),
      ).called(1);

      verify(() => mockRequestHandler.next(requestOptions)).called(1);
    });

    test('should reuse valid access token', () async {
      final firstRequestOptions = RequestOptions(
        path: '/secure',
        extra: {'secure': 'true'},
      );

      final authCredentials = AuthCredentials(
        accessToken: 'valid-token',
        refreshToken: 'refresh-token',
        accessExpiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
        refreshExpiresAt: DateTime.now().toUtc().add(const Duration(days: 30)),
      );

      final authResult = AuthenticateCommandOutput(
        credentials: authCredentials,
      );

      when(
        () => mockControlPlaneSDK.execute(any<AuthenticateCommand>()),
      ).thenAnswer((_) async => authResult);
      when(() => mockRequestHandler.next(any())).thenReturn(null);

      await interceptor.onRequest(firstRequestOptions, mockRequestHandler);

      final secondRequestOptions = RequestOptions(
        path: '/secure',
        extra: {'secure': 'true'},
      );
      await interceptor.onRequest(secondRequestOptions, mockRequestHandler);

      verify(
        () => mockControlPlaneSDK.execute(any<AuthenticateCommand>()),
      ).called(1);
      verify(() => mockRequestHandler.next(any())).called(2);
    });

    test('should refresh token when current token is expired', () async {
      final firstRequestOptions = RequestOptions(
        path: '/secure',
        extra: {'secure': 'yes'},
      );

      final expiredCredentials = AuthCredentials(
        accessToken: 'expired-token',
        refreshToken: 'refresh-token',
        accessExpiresAt: DateTime.now().toUtc().subtract(
          const Duration(hours: 1),
        ),
        refreshExpiresAt: DateTime.now().toUtc().add(const Duration(days: 30)),
      );

      final expiredAuthResult = AuthenticateCommandOutput(
        credentials: expiredCredentials,
      );

      when(
        () => mockControlPlaneSDK.execute(any<AuthenticateCommand>()),
      ).thenAnswer((_) async => expiredAuthResult);
      when(() => mockRequestHandler.next(any())).thenReturn(null);

      await interceptor.onRequest(firstRequestOptions, mockRequestHandler);

      final secondRequestOptions = RequestOptions(
        path: '/secure',
        extra: {'secure': 'yes'},
      );

      final newCredentials = AuthCredentials(
        accessToken: 'new-token',
        refreshToken: 'new-refresh-token',
        accessExpiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
        refreshExpiresAt: DateTime.now().toUtc().add(const Duration(days: 30)),
      );

      final newAuthResult = AuthenticateCommandOutput(
        credentials: newCredentials,
      );

      when(
        () => mockControlPlaneSDK.execute(any<AuthenticateCommand>()),
      ).thenAnswer((_) async => newAuthResult);

      // Act
      await interceptor.onRequest(secondRequestOptions, mockRequestHandler);

      // Assert
      expect(secondRequestOptions.headers['Authorization'], 'Bearer new-token');
      verify(
        () => mockControlPlaneSDK.execute(any<AuthenticateCommand>()),
      ).called(2);
    });
  });

  group('RefreshAuthCredentialsInterceptor - onError', () {
    test('should retry request when 401 with expired token error', () async {
      final requestOptions = RequestOptions(path: '/secure');

      final dioError = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: requestOptions,
          statusCode: HttpStatus.unauthorized,
          data: {'errorCode': 'AUTHORIZATION_TOKEN_EXPIRED'},
        ),
      );

      final authCredentials = AuthCredentials(
        accessToken: 'refreshed-token',
        refreshToken: 'refresh-token',
        accessExpiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
        refreshExpiresAt: DateTime.now().toUtc().add(const Duration(days: 30)),
      );

      final authResult = AuthenticateCommandOutput(
        credentials: authCredentials,
      );

      final retryResponse = Response(
        requestOptions: requestOptions,
        statusCode: 200,
        data: {'success': true},
      );

      when(
        () => mockControlPlaneSDK.execute(any<AuthenticateCommand>()),
      ).thenAnswer((_) async => authResult);
      when(
        () => mockDio.fetch<dynamic>(any()),
      ).thenAnswer((_) async => retryResponse);
      when(() => mockErrorHandler.resolve(any())).thenReturn(null);

      await interceptor.onError(dioError, mockErrorHandler);

      expect(
        requestOptions.headers['Authorization'],
        equals('Bearer refreshed-token'),
      );

      verify(
        () => mockControlPlaneSDK.execute(any<AuthenticateCommand>()),
      ).called(1);
      verify(() => mockDio.fetch<dynamic>(requestOptions)).called(1);
      verify(() => mockErrorHandler.resolve(retryResponse)).called(1);
      verifyNever(() => mockErrorHandler.next(any()));
    });

    test('should pass through non-401 errors', () async {
      // Arrange
      final requestOptions = RequestOptions(path: '/secure');
      final dioError = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: requestOptions,
          statusCode: HttpStatus.badRequest,
          data: {'error': 'Bad request'},
        ),
      );

      when(() => mockErrorHandler.next(any())).thenReturn(null);

      await interceptor.onError(dioError, mockErrorHandler);

      verify(() => mockErrorHandler.next(dioError)).called(1);
      verifyNever(() => mockControlPlaneSDK.execute(any()));
    });

    test('should handle retry failure gracefully', () async {
      // Arrange
      final requestOptions = RequestOptions(path: '/secure');
      final dioError = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: requestOptions,
          statusCode: HttpStatus.unauthorized,
          data: {'errorCode': 'AUTHORIZATION_TOKEN_EXPIRED'},
        ),
      );

      final refreshException = Exception('Refresh failed');

      when(
        () => mockControlPlaneSDK.execute(any<AuthenticateCommand>()),
      ).thenThrow(refreshException);
      when(() => mockErrorHandler.next(any())).thenReturn(null);

      // Act
      await interceptor.onError(dioError, mockErrorHandler);

      verify(
        () => mockControlPlaneSDK.execute(any<AuthenticateCommand>()),
      ).called(1);
      verify(() => mockErrorHandler.next(dioError)).called(1);
    });
  });

  group('RefreshAuthCredentialsInterceptor - token validation', () {
    test('should consider token invalid when expired', () async {
      final requestOptions = RequestOptions(
        path: '/secure',
        extra: {'secure': 'yes'},
      );

      final authCredentials = AuthCredentials(
        accessToken: 'expired-token',
        refreshToken: 'refresh',
        accessExpiresAt: DateTime.now().toUtc().subtract(
          const Duration(hours: 1),
        ),
        refreshExpiresAt: DateTime.now().toUtc().add(const Duration(days: 30)),
      );

      final authResult = AuthenticateCommandOutput(
        credentials: authCredentials,
      );

      when(
        () => mockControlPlaneSDK.execute(any<AuthenticateCommand>()),
      ).thenAnswer((_) async => authResult);
      when(() => mockRequestHandler.next(any())).thenReturn(null);

      await interceptor.onRequest(requestOptions, mockRequestHandler);

      final secondRequest = RequestOptions(
        path: '/secure',
        extra: {'secure': 'yes'},
      );
      await interceptor.onRequest(secondRequest, mockRequestHandler);

      verify(
        () => mockControlPlaneSDK.execute(any<AuthenticateCommand>()),
      ).called(2);
    });

    test('should consider token invalid within buffer time', () async {
      final requestOptions = RequestOptions(
        path: '/secure',
        extra: {'secure': 'yes'},
      );

      // Token expires in 1 minute (less than 2-minute buffer)
      final authCredentials = AuthCredentials(
        accessToken: 'expiring-soon-token',
        refreshToken: 'refresh-token',
        accessExpiresAt: DateTime.now().toUtc().add(const Duration(minutes: 1)),
        refreshExpiresAt: DateTime.now().toUtc().add(const Duration(days: 30)),
      );

      final authResult = AuthenticateCommandOutput(
        credentials: authCredentials,
      );

      when(
        () => mockControlPlaneSDK.execute(any<AuthenticateCommand>()),
      ).thenAnswer((_) async => authResult);
      when(() => mockRequestHandler.next(any())).thenReturn(null);

      await interceptor.onRequest(requestOptions, mockRequestHandler);

      final secondRequest = RequestOptions(
        path: '/secure',
        extra: {'secure': 'yes'},
      );
      await interceptor.onRequest(secondRequest, mockRequestHandler);

      verify(
        () => mockControlPlaneSDK.execute(any<AuthenticateCommand>()),
      ).called(2);
    });
  });

  group('RefreshAuthCredentialsInterceptor - infinite loop prevention', () {
    test('should not retry more than once to prevent infinite loop', () async {
      // Arrange
      final requestOptions = RequestOptions(path: '/secure');
      final dioError = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: requestOptions,
          statusCode: HttpStatus.unauthorized,
          data: {'errorCode': 'AUTHORIZATION_TOKEN_EXPIRED'},
        ),
      );

      final authCredentials = AuthCredentials(
        accessToken: 'refreshed-token',
        refreshToken: 'refresh-token',
        accessExpiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
        refreshExpiresAt: DateTime.now().toUtc().add(const Duration(days: 30)),
      );

      final authResult = AuthenticateCommandOutput(
        credentials: authCredentials,
      );

      // Simulate that retry also fails with 401
      final retryError = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: requestOptions,
          statusCode: HttpStatus.unauthorized,
          data: {'errorCode': 'AUTHORIZATION_TOKEN_EXPIRED'},
        ),
      );

      when(
        () => mockControlPlaneSDK.execute(any<AuthenticateCommand>()),
      ).thenAnswer((_) async => authResult);
      when(() => mockDio.fetch<dynamic>(any())).thenThrow(retryError);
      when(() => mockErrorHandler.next(any())).thenReturn(null);

      // Act
      await interceptor.onError(dioError, mockErrorHandler);

      verify(
        () => mockControlPlaneSDK.execute(any<AuthenticateCommand>()),
      ).called(1);
      verify(() => mockErrorHandler.next(dioError)).called(1);
    });

    test('should not retry if already retried', () async {
      // Arrange
      final requestOptions = RequestOptions(
        path: '/secure',
        extra: {'auth_retry': true}, // Already retried
      );
      final dioError = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: requestOptions,
          statusCode: HttpStatus.unauthorized,
          data: {'errorCode': 'AUTHORIZATION_TOKEN_EXPIRED'},
        ),
      );

      when(() => mockErrorHandler.next(any())).thenReturn(null);
      await interceptor.onError(dioError, mockErrorHandler);

      verifyNever(() => mockControlPlaneSDK.execute(any()));
      verify(() => mockErrorHandler.next(dioError)).called(1);
    });
  });
}
