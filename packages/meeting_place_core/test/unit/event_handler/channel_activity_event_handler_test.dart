import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:meeting_place_core/src/event_handler/channel_activity_event_handler.dart';
import 'package:meeting_place_core/src/event_handler/control_plane_event_handler_manager_options.dart';
import 'package:meeting_place_core/src/vdip/channel_activity_type.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'mocks/mocks.dart';

void main() {
  late ChannelActivityEventHandler handler;
  late MockLogger mockLogger;
  late MockConnectionOfferRepository mockConnectionOfferRepository;
  late MockVdipClient mockVdipClient;

  final event = ChannelActivity(
    id: const Uuid().v4(),
    did: 'did:key:channel',
    type: ChannelActivityType.vdipRequestIssuance,
  );

  final otherVdipEvent = ChannelActivity(
    id: const Uuid().v4(),
    did: 'did:key:channel',
    type: ChannelActivityType.vdipIssuedCredentials,
  );

  setUp(() {
    mockLogger = MockLogger();
    mockConnectionOfferRepository = MockConnectionOfferRepository();
    mockVdipClient = MockVdipClient();

    when(
      () => mockLogger.info(any(), name: any(named: 'name')),
    ).thenReturn(null);

    handler = ChannelActivityEventHandler(
      wallet: MockWallet(),
      mediatorService: MockMediatorService(),
      connectionManager: MockConnectionManager(),
      channelService: MockChannelService(),
      connectionOfferRepository: mockConnectionOfferRepository,
      options: const ControlPlaneEventHandlerManagerOptions(),
      logger: mockLogger,
      vdipClient: mockVdipClient,
    );
  });

  group('ChannelActivityEventHandler', () {
    test('dedupe treats different activity types on same DID as distinct', () {
      final processedEvents = [
        DiscoveryEvent<ChannelActivity>(
          id: const Uuid().v4(),
          type: ControlPlaneEventType.ChannelActivity,
          data: event,
          status: DiscoveryEventStatus.New,
        ),
      ];

      expect(
        handler.hasChannelActivityBeenProcessed(event, processedEvents),
        isTrue,
      );
      expect(
        handler.hasChannelActivityBeenProcessed(
          otherVdipEvent,
          processedEvents,
        ),
        isFalse,
      );
    });
  });
}
