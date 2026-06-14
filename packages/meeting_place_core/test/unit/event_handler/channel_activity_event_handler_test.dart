import 'dart:async';

import 'package:meeting_place_control_plane/meeting_place_control_plane.dart'
    hide ChannelActivityType;
import 'package:meeting_place_core/src/call/incoming_call_signal.dart';
import 'package:meeting_place_core/src/event_handler/channel_activity_event_handler.dart';
import 'package:meeting_place_core/src/event_handler/control_plane_event_handler_manager_options.dart';
import 'package:meeting_place_core/src/loggers/default_meeting_place_core_sdk_logger.dart';
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
      matrixService: MockMatrixService(),
      connectionOfferRepository: mockConnectionOfferRepository,
      options: const ControlPlaneEventHandlerManagerOptions(),
      logger: mockLogger,
      vdipClient: mockVdipClient,
      incomingCallSignalController:
          StreamController<IncomingCallSignal>.broadcast(),
    );
  });

  group('ChannelActivityEventHandler', () {
    ChannelActivityEventHandler makeHandler(
      StreamController<IncomingCallSignal> controller,
    ) {
      return ChannelActivityEventHandler(
        wallet: MockWallet(),
        mediatorService: MockMediatorService(),
        connectionManager: MockConnectionManager(),
        channelService: MockChannelService(),
        connectionOfferRepository: MockConnectionOfferRepository(),
        matrixService: MockMatrixService(),
        options: const ControlPlaneEventHandlerManagerOptions(),
        logger: DefaultMeetingPlaceCoreSDKLogger(),
        vdipClient: MockVdipClient(),
        incomingCallSignalController: controller,
      );
    }

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

    test(
      'call-invite emits IncomingCallSignal with the callee\'s own channel DID',
      () async {
        final controller = StreamController<IncomingCallSignal>();
        final handler = makeHandler(controller);

        final signalFuture = controller.stream.first;
        await handler.process(
          ChannelActivity(
            id: 'evt-1',
            did: 'did:key:ownChannelDid',
            type: ChannelActivityType.callInvite,
          ),
        );

        final signal = await signalFuture;
        expect(signal.ownChannelDid, 'did:key:ownChannelDid');
        await controller.close();
      },
    );

    test('call-invite returns an empty channel list', () async {
      final controller = StreamController<IncomingCallSignal>.broadcast();
      final handler = makeHandler(controller);

      final result = await handler.process(
        ChannelActivity(
          id: 'evt-2',
          did: 'did:key:ownChannelDid',
          type: ChannelActivityType.callInvite,
        ),
      );

      expect(result, isEmpty);
      await controller.close();
    });
  });
}
