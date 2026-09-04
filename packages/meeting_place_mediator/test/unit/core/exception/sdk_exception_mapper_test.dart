import 'package:meeting_place_mediator/meeting_place_mediator.dart';
import 'package:meeting_place_mediator/src/core/exception/sdk_exception_mapper.dart';
import 'package:meeting_place_mediator/src/core/mediator/mediator_exception.dart';
import 'package:test/test.dart';

void main() {
  group('toMediatorSdkException', () {
    test(
      'preserves the code and inner exception of an IMediatorException',
      () {
        final innerException = Exception('websocket refused');
        final mediatorException = MediatorException.subscribeToWebsocketError(
          innerException: innerException,
        );

        final result = toMediatorSdkException(mediatorException);

        expect(result, isA<MeetingPlaceMediatorSDKException>());
        expect(
          result.code,
          MeetingPlaceMediatorSDKErrorCode.subscribeToWebsocketError.value,
        );
        expect(result.message, mediatorException.message);
        expect(result.innerException, innerException);
      },
    );

    test(
      'falls back to the generic code for a non-mediator error, keeping it '
      'as the inner exception',
      () {
        final error = StateError('consumer callback blew up');

        final result = toMediatorSdkException(error);

        expect(result, isA<MeetingPlaceMediatorSDKException>());
        expect(result.code, MeetingPlaceMediatorSDKErrorCode.generic.value);
        expect(result.innerException, error);
      },
    );
  });
}
