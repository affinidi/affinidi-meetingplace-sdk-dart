import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_core/src/service/channel/channel_service.dart';
import 'package:meeting_place_core/src/service/connection_manager/connection_manager.dart';
import 'package:meeting_place_core/src/service/mediator/mediator_service.dart';
import 'package:meeting_place_core/src/service/message/message_service.dart';
import 'package:meeting_place_core/src/service/message/message_service_exception.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

import '../fakes/control_plane_request_fakes.dart';
import '../fixtures/contact_card_fixture.dart';

class _MockChannelService extends Mock implements ChannelService {}

class _MockMeetingPlaceControlPlaneSDK extends Mock
    implements MeetingPlaceControlPlaneSDK {}

class _MockDidResolver extends Mock implements DidResolver {}

class _MockMediatorService extends Mock implements MediatorService {}

class _MockConnectionManager extends Mock implements ConnectionManager {}

class _MockLogger extends Mock implements MeetingPlaceCoreSDKLogger {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeGroupNotifyChannelRequest());
    registerFallbackValue(FakeNotifyChannelRequest());
  });

  group('MessageService.notifyChannel', () {
    late _MockChannelService channelService;
    late _MockMeetingPlaceControlPlaneSDK controlPlaneSDK;
    late MessageService service;

    setUp(() {
      channelService = _MockChannelService();
      controlPlaneSDK = _MockMeetingPlaceControlPlaneSDK();
      service = MessageService(
        connectionManager: _MockConnectionManager(),
        didResolver: _MockDidResolver(),
        mediatorService: _MockMediatorService(),
        channelService: channelService,
        controlPlaneSDK: controlPlaneSDK,
        logger: _MockLogger(),
      );
    });

    Channel buildChannel({String? notificationToken}) => Channel(
      offerLink: 'offer',
      publishOfferDid: 'pubDid',
      mediatorDid: 'medDid',
      status: ChannelStatus.waitingForApproval,
      contactCard: ContactCardFixture.getContactCardFixture(),
      type: ChannelType.individual,
      isConnectionInitiator: true,
      otherPartyNotificationToken: notificationToken,
    );

    group('IndividualChannelNotification', () {
      test('dispatches NotifyChannelRequest with token from channel', () async {
        when(
          () => channelService.findChannelByDid('did:recipient'),
        ).thenAnswer((_) async => buildChannel(notificationToken: 'tok-1'));
        when(
          () => controlPlaneSDK.notifyChannel(any<NotifyChannelRequest>()),
        ).thenAnswer((_) async => NotifyChannelResult(success: true));

        await service.notifyChannel(
          const IndividualChannelNotification(
            recipientDid: 'did:recipient',
            type: 'chat-activity',
          ),
        );

        verify(
          () => controlPlaneSDK.notifyChannel(
            any(
              that: isA<NotifyChannelRequest>()
                  .having(
                    (request) => request.notificationToken,
                    'notificationToken',
                    'tok-1',
                  )
                  .having((request) => request.did, 'did', 'did:recipient')
                  .having((request) => request.type, 'type', 'chat-activity'),
            ),
          ),
        ).called(1);
      });

      test('no-op when channel has no notification token', () async {
        when(
          () => channelService.findChannelByDid('did:recipient'),
        ).thenAnswer((_) async => buildChannel());

        await service.notifyChannel(
          const IndividualChannelNotification(
            recipientDid: 'did:recipient',
            type: 'chat-activity',
          ),
        );

        verifyNever(
          () => controlPlaneSDK.notifyChannel(any<NotifyChannelRequest>()),
        );
      });

      test('wraps failure in MessageServiceException', () async {
        when(
          () => channelService.findChannelByDid('did:recipient'),
        ).thenAnswer((_) async => buildChannel(notificationToken: 'tok-1'));
        when(
          () => controlPlaneSDK.notifyChannel(any<NotifyChannelRequest>()),
        ).thenThrow(Exception('boom'));

        expect(
          () => service.notifyChannel(
            const IndividualChannelNotification(
              recipientDid: 'did:recipient',
              type: 'chat-activity',
            ),
          ),
          throwsA(isA<MessageServiceException>()),
        );
      });
    });

    group('GroupChannelNotification', () {
      test('dispatches GroupNotifyChannelRequest with group fields', () async {
        when(
          () => controlPlaneSDK.notifyGroupChannel(
            any<GroupNotifyChannelRequest>(),
          ),
        ).thenAnswer((_) async => NotifyGroupChannelResult(success: true));

        await service.notifyChannel(
          const GroupChannelNotification(
            groupId: 'group-1',
            type: 'chat-activity',
          ),
        );

        verify(
          () => controlPlaneSDK.notifyGroupChannel(
            any(
              that: isA<GroupNotifyChannelRequest>()
                  .having((request) => request.groupId, 'groupId', 'group-1')
                  .having((request) => request.type, 'type', 'chat-activity')
                  .having((request) => request.memberDid, 'memberDid', isNull),
            ),
          ),
        ).called(1);
        verifyNever(() => channelService.findChannelByDid(any()));
      });

      test('threads memberDid to GroupNotifyChannelRequest when set', () async {
        when(
          () => controlPlaneSDK.notifyGroupChannel(
            any<GroupNotifyChannelRequest>(),
          ),
        ).thenAnswer((_) async => NotifyGroupChannelResult(success: true));

        await service.notifyChannel(
          const GroupChannelNotification(
            groupId: 'group-1',
            type: 'call-invite-video',
            memberDid: 'did:bob',
          ),
        );

        verify(
          () => controlPlaneSDK.notifyGroupChannel(
            any(
              that: isA<GroupNotifyChannelRequest>()
                  .having((request) => request.groupId, 'groupId', 'group-1')
                  .having(
                    (request) => request.type,
                    'type',
                    'call-invite-video',
                  )
                  .having(
                    (request) => request.memberDid,
                    'memberDid',
                    'did:bob',
                  ),
            ),
          ),
        ).called(1);
      });

      test('wraps failure in MessageServiceException', () async {
        when(
          () => controlPlaneSDK.notifyGroupChannel(
            any<GroupNotifyChannelRequest>(),
          ),
        ).thenThrow(Exception('boom'));

        expect(
          () => service.notifyChannel(
            const GroupChannelNotification(
              groupId: 'group-1',
              type: 'chat-activity',
            ),
          ),
          throwsA(isA<MessageServiceException>()),
        );
      });
    });
  });
}
