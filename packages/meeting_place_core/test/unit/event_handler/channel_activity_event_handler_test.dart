import 'dart:async';

import 'package:meeting_place_control_plane/meeting_place_control_plane.dart'
    hide ChannelActivityType, ContactCard;
import 'package:meeting_place_core/src/call/call_decline_signal.dart';
import 'package:meeting_place_core/src/call/call_media_type.dart';
import 'package:meeting_place_core/src/call/incoming_call_signal.dart';
import 'package:meeting_place_core/src/call/mpx_call_event_type.dart';
import 'package:meeting_place_core/src/entity/channel.dart';
import 'package:meeting_place_core/src/event_handler/channel_activity_event_handler.dart';
import 'package:meeting_place_core/src/event_handler/control_plane_event_handler_manager_options.dart';
import 'package:meeting_place_core/src/loggers/default_meeting_place_core_sdk_logger.dart';
import 'package:meeting_place_core/src/protocol/contact_card/contact_card.dart';
import 'package:meeting_place_core/src/service/matrix/matrix_room_event.dart';
import 'package:meeting_place_core/src/vdip/channel_activity_type.dart';
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

    group('call-invite media type', () {
      const ownChannelDid = 'did:key:ownChannelDid';
      const roomId = 'room-1';

      late MockChannelService channelService;
      late MockConnectionManager connectionManager;
      late MockMatrixService matrixService;
      late MockWallet wallet;
      late MockDidManager didManager;

      Channel buildChannel() => Channel(
        offerLink: 'offer-link',
        publishOfferDid: ownChannelDid,
        mediatorDid: 'did:web:mediator',
        status: ChannelStatus.inaugurated,
        isConnectionInitiator: false,
        contactCard: ContactCard(
          did: ownChannelDid,
          type: 'individual',
          contactInfo: const {'fullName': 'Alice'},
        ),
        type: ChannelType.individual,
        transport: ChannelTransport.matrix,
        permanentChannelDid: ownChannelDid,
        matrixRoomId: roomId,
        matrixSyncMarker: 'evt-marker',
      );

      MatrixRoomEvent inviteEvent(String mediaType) => MatrixRoomEvent(
        id: 'invite-evt',
        type: MpxCallEventType.callInvite,
        senderDid: 'did:key:caller',
        roomId: roomId,
        content: {'mediaType': mediaType},
        timestamp: DateTime.now(),
      );

      ChannelActivityEventHandler buildHandler(
        StreamController<IncomingCallSignal> controller,
      ) => ChannelActivityEventHandler(
        wallet: wallet,
        mediatorService: MockMediatorService(),
        connectionManager: connectionManager,
        channelService: channelService,
        connectionOfferRepository: MockConnectionOfferRepository(),
        matrixService: matrixService,
        options: const ControlPlaneEventHandlerManagerOptions(),
        logger: DefaultMeetingPlaceCoreSDKLogger(),
        incomingCallSignalController: controller,
        callDeclineSignalController:
            StreamController<CallDeclineSignal>.broadcast(),
      );

      setUp(() {
        channelService = MockChannelService();
        connectionManager = MockConnectionManager();
        matrixService = MockMatrixService();
        wallet = MockWallet();
        didManager = MockDidManager(did: ownChannelDid);

        when(
          () => channelService.findChannelByDid(any()),
        ).thenAnswer((_) async => buildChannel());
        when(
          () => connectionManager.getDidManagerForDid(wallet, any()),
        ).thenAnswer((_) async => didManager);
      });

      Future<IncomingCallSignal> emitFor(String mediaType) async {
        when(
          () => matrixService.fetchRoomHistory(
            any(),
            didManager: didManager,
            forceSync: any(named: 'forceSync'),
          ),
        ).thenAnswer((_) async => [inviteEvent(mediaType)]);

        final controller = StreamController<IncomingCallSignal>();
        final handler = buildHandler(controller);
        final signalFuture = controller.stream.first;
        await handler.process(
          ChannelActivity(
            id: 'evt-media',
            did: ownChannelDid,
            type: ChannelActivityType.callInvite,
          ),
        );
        final signal = await signalFuture;
        await controller.close();
        return signal;
      }

      test('reads audio media type from the call invite room event', () async {
        final signal = await emitFor('audio');
        expect(signal.mediaType, CallMediaType.audio);
      });

      test('reads video media type from the call invite room event', () async {
        final signal = await emitFor('video');
        expect(signal.mediaType, CallMediaType.video);
      });

      test('defaults to video when room ID is null', () async {
        final channelWithoutRoom = Channel(
          offerLink: 'offer-link',
          publishOfferDid: ownChannelDid,
          mediatorDid: 'did:web:mediator',
          status: ChannelStatus.inaugurated,
          isConnectionInitiator: false,
          contactCard: ContactCard(
            did: ownChannelDid,
            type: 'individual',
            contactInfo: const {'fullName': 'Alice'},
          ),
          type: ChannelType.individual,
          transport: ChannelTransport.matrix,
          permanentChannelDid: ownChannelDid,
          matrixRoomId: null,
          matrixSyncMarker: 'evt-marker',
        );
        when(
          () => channelService.findChannelByDid(any()),
        ).thenAnswer((_) async => channelWithoutRoom);

        final controller = StreamController<IncomingCallSignal>();
        final handler = buildHandler(controller);
        final signalFuture = controller.stream.first;
        await handler.process(
          ChannelActivity(
            id: 'evt-no-room',
            did: ownChannelDid,
            type: ChannelActivityType.callInvite,
          ),
        );
        final signal = await signalFuture;
        await controller.close();

        expect(signal.mediaType, CallMediaType.video);
      });

      test('defaults to video when no invite event in room history', () async {
        when(
          () => matrixService.fetchRoomHistory(any(), didManager: didManager),
        ).thenAnswer((_) async => []);

        final controller = StreamController<IncomingCallSignal>();
        final handler = buildHandler(controller);
        final signalFuture = controller.stream.first;
        await handler.process(
          ChannelActivity(
            id: 'evt-empty-history',
            did: ownChannelDid,
            type: ChannelActivityType.callInvite,
          ),
        );
        final signal = await signalFuture;
        await controller.close();

        expect(signal.mediaType, CallMediaType.video);
      });

      test(
        'defaults to video when mediaType is missing from event content',
        () async {
          when(
            () => matrixService.fetchRoomHistory(any(), didManager: didManager),
          ).thenAnswer(
            (_) async => [
              MatrixRoomEvent(
                id: 'invite-evt',
                type: MpxCallEventType.callInvite,
                senderDid: 'did:key:caller',
                roomId: roomId,
                content: {}, // Missing 'mediaType'
                timestamp: DateTime.now(),
              ),
            ],
          );

          final controller = StreamController<IncomingCallSignal>();
          final handler = buildHandler(controller);
          final signalFuture = controller.stream.first;
          await handler.process(
            ChannelActivity(
              id: 'evt-missing-media',
              did: ownChannelDid,
              type: ChannelActivityType.callInvite,
            ),
          );
          final signal = await signalFuture;
          await controller.close();

          expect(signal.mediaType, CallMediaType.video);
        },
      );

      test('defaults to video when mediaType value is unknown', () async {
        when(
          () => matrixService.fetchRoomHistory(any(), didManager: didManager),
        ).thenAnswer(
          (_) async => [
            MatrixRoomEvent(
              id: 'invite-evt',
              type: MpxCallEventType.callInvite,
              senderDid: 'did:key:caller',
              roomId: roomId,
              content: {'mediaType': 'invalid-type'},
              timestamp: DateTime.now(),
            ),
          ],
        );

        final controller = StreamController<IncomingCallSignal>();
        final handler = buildHandler(controller);
        final signalFuture = controller.stream.first;
        await handler.process(
          ChannelActivity(
            id: 'evt-invalid-media',
            did: ownChannelDid,
            type: ChannelActivityType.callInvite,
          ),
        );
        final signal = await signalFuture;
        await controller.close();

        expect(signal.mediaType, CallMediaType.video);
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
