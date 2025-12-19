import 'package:meeting_place_control_plane/src/api/retry_interceptor.dart';
import 'package:test/test.dart';
import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

class MockErrorInterceptorHandler extends Mock
    implements ErrorInterceptorHandler {}

void main() {
  group('RetryInterceptor', () {
    late MockDio mockDio;
    late RetryInterceptor interceptor;
    late MockErrorInterceptorHandler mockHandler;

    setUp(() {
      mockDio = MockDio();
      interceptor = RetryInterceptor(
        dio: mockDio,
        maxRetries: 3,
        retryDelay: Duration(milliseconds: 10),
      );
      mockHandler = MockErrorInterceptorHandler();

      // Register fallback values for mocktail
      registerFallbackValue(RequestOptions(path: '/test'));
      registerFallbackValue(Options());
      registerFallbackValue(
        DioException(
          requestOptions: RequestOptions(path: '/fallback'),
          type: DioExceptionType.unknown,
        ),
      );
    });

    test('should not retry if error type is not retryable', () async {
      final err = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.badResponse,
      );

      await interceptor.onError(err, mockHandler);

      verify(() => mockHandler.next(err)).called(1);
      verifyNever(
        () => mockDio.request<dynamic>(
          any(),
          options: any(named: 'options'),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
        ),
      );
    });

    group('retryable errors', () {
      final retryableTypes = [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.connectionError,
      ];

      for (final retryableType in retryableTypes) {
        test(
          'should retry once for ${retryableType.name} and resolve response',
          () async {
            final err = DioException(
              requestOptions: RequestOptions(
                path: '/test',
                extra: {'retry_count': 0},
              ),
              type: retryableType,
            );

            final fakeResponse = Response(
              requestOptions: err.requestOptions,
              statusCode: 200,
              data: 'success',
            );

            // Stub dio.request to return a successful response
            when(
              () => mockDio.request<dynamic>(
                any(),
                options: any(named: 'options'),
                data: any(named: 'data'),
                queryParameters: any(named: 'queryParameters'),
              ),
            ).thenAnswer((_) async => fakeResponse);

            // Stub handler.resolve
            when(() => mockHandler.resolve(fakeResponse)).thenReturn(null);

            await interceptor.onError(err, mockHandler);

            // Verify that retry was attempted
            verify(
              () => mockDio.request<dynamic>(
                '/test',
                options: any(named: 'options'),
                data: any(named: 'data'),
                queryParameters: any(named: 'queryParameters'),
              ),
            ).called(1);

            // Verify that handler.resolve was called with the successful response
            verify(() => mockHandler.resolve(fakeResponse)).called(1);
          },
        );
      }
    });

    test('should retry up to maxRetries and then call handler.next', () async {
      final err = DioException(
        requestOptions: RequestOptions(
          path: '/test',
          extra: {'retry_count': 0},
        ),
        type: DioExceptionType.connectionTimeout,
      );

      when(
        () => mockDio.request<dynamic>(
          any(),
          options: any(named: 'options'),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenThrow(err);

      when(() => mockHandler.next(err)).thenReturn(null);

      for (var i = 0; i < interceptor.maxRetries; i++) {
        await interceptor.onError(
          DioException(
            requestOptions: RequestOptions(
              path: '/test',
              extra: {'retry_count': i},
            ),
            type: DioExceptionType.connectionTimeout,
          ),
          mockHandler,
        );
      }

      // Verify that request was attempted maxRetries times
      verify(
        () => mockDio.request<dynamic>(
          '/test',
          options: any(named: 'options'),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).called(interceptor.maxRetries);

      // After retries, handler.next should be called
      verify(
        () => mockHandler.next(any(that: isA<DioException>())),
      ).called(interceptor.maxRetries);
    });
  });
}
