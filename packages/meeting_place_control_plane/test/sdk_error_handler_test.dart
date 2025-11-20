import 'package:dio/dio.dart';
import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:meeting_place_control_plane/src/core/sdk_error_handler.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockControlPlaneSDKLogger extends Mock implements ControlPlaneSDKLogger {}

void main() {
  late SDKErrorHandler errorHandler;
  late MockControlPlaneSDKLogger mockLogger;
  const testControlPlaneDid = 'did:web:123456789abcdefghi';

  setUp(() {
    mockLogger = MockControlPlaneSDKLogger();
    errorHandler = SDKErrorHandler(
      logger: mockLogger,
      controlPlaneDid: testControlPlaneDid,
    );
  });

  group('SDKErrorHandler', () {
    test('should return successful result when operation succeeds', () async {
      const expectedResult = 'success';
      final result = await errorHandler.handleError(() async => expectedResult);

      expect(result, equals(expectedResult));
      verifyNever(() => mockLogger.error(any(),
          error: any(named: 'error'),
          stackTrace: any(named: 'stackTrace'),
          name: any(named: 'name')));
    });

    test(
        '''should handle ControlPlaneException and throw ControlPlaneSDKException''',
        () async {
      final controlPlaneException = AcceptOfferException.limitExceededError();

      expect(
        () => errorHandler.handleError<void>(() => throw controlPlaneException),
        throwsA(
          isA<ControlPlaneSDKException>()
              .having((e) => e.message, 'message',
                  '''Offer acceptance failed: the maximum number of allowed offer usages has been reached.''')
              .having((e) => e.code, 'code',
                  ControlPlaneSDKErrorCode.acceptOfferLimitExceeded.value)
              .having((e) => e.innerException, 'innerException',
                  controlPlaneException),
        ),
      );
    });

    group('Network error handling', () {
      final networkErrorTypes = [
        DioExceptionType.connectionError,
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ];

      for (final errorType in networkErrorTypes) {
        test(
            '''should handle DioException with $errorType and set network error code''',
            () async {
          final dioException = DioException(
            requestOptions: RequestOptions(path: '/test'),
            type: errorType,
            message: 'Network error occurred',
          );

          expect(
            () => errorHandler.handleError<void>(() => throw dioException),
            throwsA(
              isA<ControlPlaneSDKException>()
                  .having((e) => e.code, 'code',
                      ControlPlaneSDKErrorCode.networkError.value)
                  .having(
                      (e) => e.innerException, 'innerException', dioException),
            ),
          );
        });
      }
    });

    test('should throw generic SDK exception', () async {
      // Arrange
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.badResponse,
        message: 'Bad response',
      );

      expect(
        () => errorHandler.handleError<void>(() => throw dioException),
        throwsA(isA<ControlPlaneSDKException>()
            .having(
                (e) => e.code, 'code', ControlPlaneSDKErrorCode.generic.value)
            .having((e) => e.innerException, 'innerException', dioException)),
      );
    });

    test('should handle generic exception and throw ControlPlaneSDKException',
        () async {
      // Arrange
      final genericException = Exception('Generic error');

      // Act & Assert
      expect(
        () => errorHandler.handleError<void>(() => throw genericException),
        throwsA(
          isA<ControlPlaneSDKException>()
              .having(
                  (e) => e.code, 'code', ControlPlaneSDKErrorCode.generic.value)
              .having(
                  (e) => e.innerException, 'innerException', genericException)
              .having((e) => e.message, 'message', contains('Generic error')),
        ),
      );
    });
  });
}
