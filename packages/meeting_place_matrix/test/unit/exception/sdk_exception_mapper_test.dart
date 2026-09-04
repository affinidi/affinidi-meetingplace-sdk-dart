import 'package:meeting_place_matrix/meeting_place_matrix.dart';
import 'package:meeting_place_matrix/src/exception/sdk_exception_mapper.dart';
import 'package:meeting_place_matrix/src/matrix_auth_exception.dart';
import 'package:meeting_place_matrix/src/matrix_service_exception.dart';
import 'package:test/test.dart';

void main() {
  group('toMatrixSdkException', () {
    test('passes an already-unified exception through unchanged', () {
      final original = MatrixServiceException.roomNotFound('!room:example.org');

      final result = toMatrixSdkException(original);

      expect(result, same(original));
    });

    test('maps a MatrixAuthException to the matrixAuthError code', () {
      const authException = MatrixAuthException('token expired');

      final result = toMatrixSdkException(authException);

      expect(result, isA<MeetingPlaceMatrixSDKException>());
      expect(result.code, MeetingPlaceMatrixSDKErrorCode.matrixAuthError);
      expect(result.innerException, authException);
    });

    test(
      'falls back to the generic code for any other error, keeping it as '
      'the inner exception',
      () {
        final error = StateError('unexpected failure');

        final result = toMatrixSdkException(error);

        expect(result, isA<MeetingPlaceMatrixSDKException>());
        expect(result.code, MeetingPlaceMatrixSDKErrorCode.generic);
        expect(result.innerException, error);
      },
    );
  });
}
