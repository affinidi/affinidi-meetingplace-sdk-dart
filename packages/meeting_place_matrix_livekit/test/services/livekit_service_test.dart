import 'package:flutter_test/flutter_test.dart';
import 'package:meeting_place_matrix_livekit/src/services/livekit_service.dart';

import '../mocks/mocks.dart';

void main() {
  group('LivekitService', () {
    late LivekitService service;

    setUp(() {
      service = LivekitService();
    });

    group('before connecting', () {
      test('participants returns empty list', () {
        expect(service.participants, isEmpty);
      });

      test('ownParticipantId is null', () {
        expect(service.ownParticipantId, isNull);
      });
    });

    group('disconnect', () {
      test('is safe to call without a prior connect', () async {
        await expectLater(service.disconnect(), completes);
      });

      test(
        'marks service as disposed so a subsequent connect is a no-op',
        () async {
          await service.disconnect();
          // connect() on a disposed service must return without throwing,
          // even though there is no real SFU to connect to.
          await expectLater(
            service.connect(
              url: 'wss://example.com',
              token: 'token',
              keyProvider: MockBaseKeyProvider(),
            ),
            completes,
          );
        },
      );
    });
  });
}
