import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_core/src/event_handler/channel_activity_event_handler.dart';
import 'package:meeting_place_core/src/event_handler/control_plane_event_handler_manager_options.dart';
import 'package:meeting_place_core/src/event_handler/channel_activity_type.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'mocks/mocks.dart';

import '../../fixtures/contact_card_fixture.dart';

void main() {
  late ChannelActivityEventHandler handler;
  late MockLogger mockLogger;
  late MockConnectionOfferRepository mockConnectionOfferRepository;
  late MockChannelService mockChannelService;

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
    mockChannelService = MockChannelService();

    when(
      () => mockLogger.info(any(), name: any(named: 'name')),
    ).thenReturn(null);

    handler = ChannelActivityEventHandler(
      wallet: MockWallet(),
      mediatorService: MockMediatorService(),
      connectionManager: MockConnectionManager(),
      channelService: mockChannelService,
      channelTransport: MockMeetingPlaceTransport(),
      connectionOfferRepository: mockConnectionOfferRepository,
      options: const ControlPlaneEventHandlerManagerOptions(),
      logger: mockLogger,
    );
  });

  group('ChannelActivityEventHandler', () {
    test('dedupe treats different activity types on same DID as distinct', () {
      final processedEvents = [
        ControlPlaneEvent<ChannelActivity>(
          id: const Uuid().v4(),
          type: ControlPlaneEventType.ChannelActivity,
          data: event,
          status: ControlPlaneEventStatus.New,
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

    test(
      'process returns channel for unhandled activity type (e.g. call-invite-video)',
      () async {
        const channelDid = 'did:key:channel';
        final channel = Channel(
          offerLink: 'offer',
          publishOfferDid: 'pubDid',
          mediatorDid: 'medDid',
          status: ChannelStatus.inaugurated,
          contactCard: ContactCardFixture.getContactCardFixture(),
          type: ChannelType.individual,
          transport: ChannelTransport.matrix,
          isConnectionInitiator: true,
          permanentChannelDid: channelDid,
        );

        when(
          () => mockChannelService.findChannelByDid(channelDid),
        ).thenAnswer((_) async => channel);

        final unknownActivity = ChannelActivity(
          id: const Uuid().v4(),
          did: channelDid,
          type: 'call-invite-video',
        );

        final result = await handler.process(unknownActivity);

        expect(result, [channel]);
      },
    );
  });
}
