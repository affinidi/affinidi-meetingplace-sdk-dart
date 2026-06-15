import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_core/src/event_handler/control_plane_event_handler_manager.dart';
import 'package:meeting_place_core/src/event_handler/control_plane_event_stream_manager.dart';
import 'package:meeting_place_core/src/service/connection_service.dart';
import 'package:meeting_place_core/src/service/mediator/fetch_messages_options.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import '../../fixtures/contact_card_fixture.dart';
import 'mocks/mocks.dart';

class MockConnectionService extends Mock implements ConnectionService {}

class MockMeetingPlaceMediatorSDK extends Mock
    implements MeetingPlaceMediatorSDK {}

class MockGroupRepository extends Mock implements GroupRepository {}

class RecordingControlPlaneEventStreamManager
    extends ControlPlaneEventStreamManager {
  RecordingControlPlaneEventStreamManager({super.logger});

  final pushedEvents = <ControlPlaneStreamEvent>[];

  @override
  void pushEvent(ControlPlaneStreamEvent event) {
    pushedEvents.add(event);
    super.pushEvent(event);
  }
}

void main() {
  const channelDid = 'did:key:channel';
  const permanentChannelDid = 'did:key:permanent-channel';
  const mediatorDid = 'did:web:mediator';

  late ControlPlaneEventManager manager;
  late RecordingControlPlaneEventStreamManager streamManager;
  late MockWallet mockWallet;
  late MockChannelService mockChannelService;
  late MockConnectionManager mockConnectionManager;
  late MockMediatorService mockMediatorService;
  late MockDidManager mockDidManager;
  late MockLogger mockLogger;

  Channel channelWithStatus(ChannelStatus status) {
    return Channel(
      offerLink: 'offer-link',
      publishOfferDid: channelDid,
      mediatorDid: mediatorDid,
      status: status,
      isConnectionInitiator: true,
      contactCard: ContactCardFixture.getContactCardFixture(),
      type: ChannelType.individual,
      permanentChannelDid: permanentChannelDid,
    );
  }

  ChannelActivity chatActivity() {
    return ChannelActivity(
      id: const Uuid().v4(),
      did: channelDid,
      type: 'chat-activity',
    );
  }

  DiscoveryEvent<ChannelActivity> channelActivityEvent({
    required ChannelActivity activity,
    String? id,
  }) {
    return DiscoveryEvent<ChannelActivity>(
      id: id ?? const Uuid().v4(),
      type: ControlPlaneEventType.ChannelActivity,
      data: activity,
      status: DiscoveryEventStatus.New,
    );
  }

  void stubChatActivity(Channel channel) {
    when(
      () => mockChannelService.findChannelByDid(channelDid),
    ).thenAnswer((_) async => channel);

    when(
      () => mockConnectionManager.getDidManagerForDid(
        mockWallet,
        permanentChannelDid,
      ),
    ).thenAnswer((_) async => mockDidManager);

    when(
      () => mockMediatorService.fetchMessages(
        didManager: mockDidManager,
        mediatorDid: mediatorDid,
        options: any(named: 'options'),
      ),
    ).thenAnswer((_) async => []);

    when(
      () => mockChannelService.updateChannelSequence(
        any(),
        sequenceNumber: any(named: 'sequenceNumber'),
        messageSyncMarker: any(named: 'messageSyncMarker'),
      ),
    ).thenAnswer((_) async {});
  }

  setUpAll(() {
    registerFallbackValue(const FetchMessagesOptions());
    registerFallbackValue(channelWithStatus(ChannelStatus.approved));
  });

  setUp(() {
    mockWallet = MockWallet();
    mockChannelService = MockChannelService();
    mockConnectionManager = MockConnectionManager();
    mockMediatorService = MockMediatorService();
    mockDidManager = MockDidManager(did: permanentChannelDid);
    mockLogger = MockLogger();

    when(
      () => mockLogger.info(any(), name: any(named: 'name')),
    ).thenReturn(null);
    when(
      () => mockLogger.warning(any(), name: any(named: 'name')),
    ).thenReturn(null);
    when(
      () => mockLogger.error(
        any(),
        error: any(named: 'error'),
        stackTrace: any(named: 'stackTrace'),
        name: any(named: 'name'),
      ),
    ).thenReturn(null);

    streamManager = RecordingControlPlaneEventStreamManager(logger: mockLogger);

    manager = ControlPlaneEventManager(
      wallet: mockWallet,
      mediatorSDK: MockMeetingPlaceMediatorSDK(),
      mediatorService: mockMediatorService,
      controlPlaneSDK: MockControlPlaneSDK(),
      connectionService: MockConnectionService(),
      connectionManager: mockConnectionManager,
      connectionOfferRepository: MockConnectionOfferRepository(),
      groupRepository: MockGroupRepository(),
      channelRepository: MockChannelRepository(),
      channelService: mockChannelService,
      matrixService: MockMatrixService(),
      identityService: MockIdentityService(),
      streamManager: streamManager,
      didResolver: MockDidResolver(),
      vdipClient: MockVdipClient(),
      logger: mockLogger,
    );
  });

  tearDown(() {
    streamManager.dispose();
  });

  group('ControlPlaneEventManager.handleEventsBatch', () {
    test(
      'defers acknowledgement for ChannelActivity on non-inaugurated channels',
      () async {
        stubChatActivity(channelWithStatus(ChannelStatus.approved));
        final event = channelActivityEvent(activity: chatActivity());

        final acknowledged = await manager.handleEventsBatch([event]);

        expect(acknowledged, isEmpty);
      },
    );

    test('acknowledges ChannelActivity when channel is inaugurated', () async {
      final channel = channelWithStatus(ChannelStatus.inaugurated);
      stubChatActivity(channel);
      final event = channelActivityEvent(activity: chatActivity());

      final acknowledged = await manager.handleEventsBatch([event]);

      expect(acknowledged, contains(event));
      expect(streamManager.pushedEvents, hasLength(1));
      expect(streamManager.pushedEvents.single.channel, same(channel));
      expect(
        streamManager.pushedEvents.single.type,
        ControlPlaneEventType.ChannelActivity,
      );
    });

    test(
      'acknowledges deduplicated ChannelActivity with empty channels',
      () async {
        final activity = chatActivity();
        stubChatActivity(channelWithStatus(ChannelStatus.inaugurated));
        final first = channelActivityEvent(activity: activity, id: 'first');
        final duplicate = channelActivityEvent(
          activity: activity,
          id: 'duplicate',
        );

        final acknowledged = await manager.handleEventsBatch([
          first,
          duplicate,
        ]);

        expect(acknowledged, containsAll([first, duplicate]));
      },
    );

    test('skips stream emission for non-inaugurated ChannelActivity', () async {
      stubChatActivity(channelWithStatus(ChannelStatus.approved));
      final event = channelActivityEvent(activity: chatActivity());

      await manager.handleEventsBatch([event]);

      expect(streamManager.pushedEvents, isEmpty);
    });
  });
}
