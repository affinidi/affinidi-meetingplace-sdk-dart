import 'dart:async';

import 'package:meeting_place_control_plane/meeting_place_control_plane.dart'
    hide ContactCard;
import 'package:meeting_place_core/meeting_place_core.dart'
    show ChannelActivityType;
import 'package:meeting_place_core/src/call/call_decline_signal.dart';
import 'package:meeting_place_core/src/call/call_media_type.dart';
import 'package:meeting_place_core/src/call/incoming_call_signal.dart';
import 'package:meeting_place_core/src/event_handler/channel_activity_event_handler.dart';
import 'package:meeting_place_core/src/event_handler/control_plane_event_handler_manager_options.dart';
import 'package:meeting_place_core/src/loggers/default_meeting_place_core_sdk_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'mocks/mocks.dart';

void main() {
  late ChannelActivityEventHandler handler;
  late MockLogger mockLogger;
  late MockConnectionOfferRepository mockConnectionOfferRepository;

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
      incomingCallSignalController:
          StreamController<IncomingCallSignal>.broadcast(),
      callDeclineSignalController:
          StreamController<CallDeclineSignal>.broadcast(),
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
        incomingCallSignalController: controller,
        callDeclineSignalController:
            StreamController<CallDeclineSignal>.broadcast(),
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
            type: ChannelActivityType.callInviteVideo,
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
          type: ChannelActivityType.callInviteVideo,
        ),
      );

      expect(result, isEmpty);
      await controller.close();
    });

    group('call-invite media type', () {
      const ownChannelDid = 'did:key:ownChannelDid';

      Future<List<IncomingCallSignal>> collectSignals(
        ChannelActivity activity,
      ) async {
        final controller = StreamController<IncomingCallSignal>.broadcast();
        final handler = makeHandler(controller);
        final signals = <IncomingCallSignal>[];
        final sub = controller.stream.listen(signals.add);
        await handler.process(activity);
        await pumpEventQueue();
        await sub.cancel();
        await controller.close();
        return signals;
      }

      test('call-invite emits a single video signal', () async {
        final signals = await collectSignals(
          ChannelActivity(
            id: 'evt-media',
            did: ownChannelDid,
            type: ChannelActivityType.callInviteVideo,
          ),
        );

        expect(signals, hasLength(1));
        expect(signals.single.ownChannelDid, ownChannelDid);
        expect(signals.single.mediaType, CallMediaType.video);
      });

      test('call-invite-audio emits a single audio signal', () async {
        final signals = await collectSignals(
          ChannelActivity(
            id: 'evt-media-audio',
            did: ownChannelDid,
            type: ChannelActivityType.callInviteAudio,
          ),
        );

        expect(signals, hasLength(1));
        expect(signals.single.ownChannelDid, ownChannelDid);
        expect(signals.single.mediaType, CallMediaType.audio);
      });
    });

    test(
      'call-decline emits CallDeclineSignal with the caller\'s own channel DID',
      () async {
        final declineController = StreamController<CallDeclineSignal>();
        final handler = ChannelActivityEventHandler(
          wallet: MockWallet(),
          mediatorService: MockMediatorService(),
          connectionManager: MockConnectionManager(),
          channelService: MockChannelService(),
          connectionOfferRepository: MockConnectionOfferRepository(),
          matrixService: MockMatrixService(),
          options: const ControlPlaneEventHandlerManagerOptions(),
          logger: DefaultMeetingPlaceCoreSDKLogger(),
          incomingCallSignalController:
              StreamController<IncomingCallSignal>.broadcast(),
          callDeclineSignalController: declineController,
        );

        final signalFuture = declineController.stream.first;
        await handler.process(
          ChannelActivity(
            id: 'evt-3',
            did: 'did:key:callerChannelDid',
            type: ChannelActivityType.callDecline,
          ),
        );

        final signal = await signalFuture;
        expect(signal.ownChannelDid, 'did:key:callerChannelDid');
        await declineController.close();
      },
    );

    test('call-decline returns an empty channel list', () async {
      final declineController = StreamController<CallDeclineSignal>.broadcast();
      final handler = ChannelActivityEventHandler(
        wallet: MockWallet(),
        mediatorService: MockMediatorService(),
        connectionManager: MockConnectionManager(),
        channelService: MockChannelService(),
        connectionOfferRepository: MockConnectionOfferRepository(),
        matrixService: MockMatrixService(),
        options: const ControlPlaneEventHandlerManagerOptions(),
        logger: DefaultMeetingPlaceCoreSDKLogger(),
        incomingCallSignalController:
            StreamController<IncomingCallSignal>.broadcast(),
        callDeclineSignalController: declineController,
      );

      final result = await handler.process(
        ChannelActivity(
          id: 'evt-4',
          did: 'did:key:callerChannelDid',
          type: ChannelActivityType.callDecline,
        ),
      );

      expect(result, isEmpty);
      await declineController.close();
    });
  });
}
