import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_core/src/event_handler/exceptions/group_membership_finalised_exception.dart';
import 'package:meeting_place_core/src/sdk/sdk_error_handler.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockLogger extends Mock implements MeetingPlaceCoreSDKLogger {}

void main() {
  late SDKErrorHandler errorHandler;
  late MockLogger mockLogger;

  setUp(() {
    mockLogger = MockLogger();
    errorHandler = SDKErrorHandler(logger: mockLogger);
  });

  group('SDKErrorHandler.handleError', () {
    test('returns result when operation succeeds', () async {
      final result = await errorHandler.handleError(() async => 'success');
      expect(result, equals('success'));
    });

    test('throws MeetingPlaceCoreSDKException for SDKException', () async {
      final sdkException = GroupMembershipFinalisedException(
          message: 'SDK error', code: MeetingPlaceCoreSDKErrorCode.generic);

      expect(
        () => errorHandler.handleError(() async => throw sdkException),
        throwsA(isA<MeetingPlaceCoreSDKException>()
            .having((e) => e.message, 'message', 'SDK error')),
      );
    });

    test('throws MeetingPlaceCoreSDKException for ControlPlaneSDKException',
        () async {
      final controlPlaneException = ControlPlaneSDKException(
          message: 'ControlPlane error',
          code: ControlPlaneSDKErrorCode.networkError.value,
          innerException: ControlPlaneSDKException(
              message: 'Control Plane SDK exception',
              code: ControlPlaneSDKErrorCode.networkError.value,
              innerException: Exception('Inner exception')));

      expect(
        () => errorHandler.handleError(() async => throw controlPlaneException),
        throwsA(isA<MeetingPlaceCoreSDKException>().having((e) => e.code,
            'code', ControlPlaneSDKErrorCode.networkError.value)),
      );
    });

    test(
        '''throws MeetingPlaceCoreSDKException for MeetingPlaceMediatorSDKException''',
        () async {
      final mediatorException = MeetingPlaceMediatorSDKException(
          message: 'Mediator error',
          code: 'MED_ERR',
          innerException: Exception('Inner exception'));

      expect(
        () => errorHandler.handleError(() async => throw mediatorException),
        throwsA(isA<MeetingPlaceCoreSDKException>()
            .having((e) => e.code, 'code', 'MED_ERR')),
      );
    });

    test('throws MeetingPlaceCoreSDKException for generic exception', () async {
      final genericException = Exception('Generic failure');

      expect(
        () => errorHandler.handleError(() async => throw genericException),
        throwsA(isA<MeetingPlaceCoreSDKException>()
            .having((e) => e.code, 'code', 'generic')),
      );
    });
  });
}
