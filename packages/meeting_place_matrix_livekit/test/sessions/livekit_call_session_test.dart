import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meeting_place_matrix_livekit/meeting_place_matrix_livekit.dart';

import '../mocks/mocks.dart';

void main() {
  const otherPartyChannelDid = 'did:peer:other-party';

  late ProviderContainer container;
  late MockMeetingPlaceCoreSDKLogger logger;
  late LiveKitCallSession session;

  setUp(() {
    container = ProviderContainer();
    logger = MockMeetingPlaceCoreSDKLogger();
    session = LiveKitCallSession.create(
      container: container,
      otherPartyChannelDid: otherPartyChannelDid,
      logger: logger,
    );
  });

  group('plugin-internal accessors', () {
    test('exposes the injected otherPartyChannelDid', () {
      expect(session.otherPartyChannelDid, otherPartyChannelDid);
    });

    test('exposes the injected container', () {
      expect(session.container, same(container));
    });
  });

  group('disposeContainer', () {
    test('disposes the backing container', () {
      final probe = Provider<int>((ref) => 1);

      session.disposeContainer();

      expect(() => container.read(probe), throwsStateError);
    });
  });
}
