import 'package:meeting_place_matrix/meeting_place_matrix.dart';
import 'package:test/test.dart';

void main() {
  group('MatrixConfig.outgoingCallTimeout', () {
    test('defaults to 60 seconds', () {
      final config = MatrixConfig(
        mediatorDid: 'did:test:mediator',
        controlPlaneDid: 'did:test:control-plane',
        homeserver: Uri.parse('https://matrix.example.com'),
        databaseFactory: const UnsupportedMatrixDatabaseFactory(),
        deviceId: 'TESTDEVICEID',
      );

      expect(config.outgoingCallTimeout, const Duration(seconds: 60));
    });

    test('uses the provided timeout override', () {
      final config = MatrixConfig(
        mediatorDid: 'did:test:mediator',
        controlPlaneDid: 'did:test:control-plane',
        homeserver: Uri.parse('https://matrix.example.com'),
        databaseFactory: const UnsupportedMatrixDatabaseFactory(),
        deviceId: 'TESTDEVICEID',
        outgoingCallTimeout: const Duration(seconds: 25),
      );

      expect(config.outgoingCallTimeout, const Duration(seconds: 25));
    });
  });
}
