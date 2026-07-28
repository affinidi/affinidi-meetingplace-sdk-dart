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

import '../fixtures/contact_card_fixture.dart';

class _MockChannelService extends Mock implements ChannelService {}

class _MockControlPlaneSDK extends Mock implements ControlPlaneSDK {}

class _MockDidResolver extends Mock implements DidResolver {}

class _MockMediatorService extends Mock implements MediatorService {}

class _MockConnectionManager extends Mock implements ConnectionManager {}

class _MockLogger extends Mock implements MeetingPlaceCoreSDKLogger {}

class _FakeNotifyChannelCommand extends Fake implements NotifyChannelCommand {}

class _FakeGroupNotifyChannelCommand extends Fake
    implements GroupNotifyChannelCommand {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeNotifyChannelCommand());
    registerFallbackValue(_FakeGroupNotifyChannelCommand());
  });

  group('MessageService.notifyChannel', () {
    late _MockChannelService channelService;
    late _MockControlPlaneSDK controlPlaneSDK;
    late MessageService service;

    setUp(() {
      channelService = _MockChannelService();
      controlPlaneSDK = _MockControlPlaneSDK();
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
      test('dispatches NotifyChannelCommand with token from channel', () async {
        when(
          () => channelService.findChannelByDidOrNull('did:recipient'),
        ).thenAnswer((_) async => buildChannel(notificationToken: 'tok-1'));
        when(
          () => controlPlaneSDK.execute<NotifyChannelCommandOutput>(any()),
        ).thenAnswer((_) async => NotifyChannelCommandOutput(success: true));

        await service.notifyChannel(
          const IndividualChannelNotification(
            recipientDid: 'did:recipient',
            type: 'chat-activity',
          ),
        );

        final captured =
            verify(
                  () => controlPlaneSDK.execute<NotifyChannelCommandOutput>(
                    captureAny(),
                  ),
                ).captured.single
                as NotifyChannelCommand;
        expect(captured.notificationToken, 'tok-1');
        expect(captured.did, 'did:recipient');
        expect(captured.type, 'chat-activity');
      });

      test('no-op when channel has no notification token', () async {
        when(
          () => channelService.findChannelByDidOrNull('did:recipient'),
        ).thenAnswer((_) async => buildChannel());

        await service.notifyChannel(
          const IndividualChannelNotification(
            recipientDid: 'did:recipient',
            type: 'chat-activity',
          ),
        );

        verifyNever(
          () => controlPlaneSDK.execute<NotifyChannelCommandOutput>(any()),
        );
      });

      test('wraps failure in MessageServiceException', () async {
        when(
          () => channelService.findChannelByDidOrNull('did:recipient'),
        ).thenAnswer((_) async => buildChannel(notificationToken: 'tok-1'));
        when(
          () => controlPlaneSDK.execute<NotifyChannelCommandOutput>(any()),
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
      test('dispatches GroupNotifyChannelCommand with group fields', () async {
        when(
          () => controlPlaneSDK.execute<GroupNotifyChannelCommandOutput>(any()),
        ).thenAnswer(
          (_) async => GroupNotifyChannelCommandOutput(success: true),
        );

        await service.notifyChannel(
          const GroupChannelNotification(
            offerLink: 'offer://group',
            groupDid: 'did:group',
            type: 'chat-activity',
          ),
        );

        final captured =
            verify(
                  () => controlPlaneSDK
                      .execute<GroupNotifyChannelCommandOutput>(captureAny()),
                ).captured.single
                as GroupNotifyChannelCommand;
        expect(captured.offerLink, 'offer://group');
        expect(captured.groupDid, 'did:group');
        expect(captured.type, 'chat-activity');
        expect(captured.memberDid, isNull);
        verifyNever(() => channelService.findChannelByDidOrNull(any()));
      });

      test('threads memberDid to GroupNotifyChannelCommand when set', () async {
        when(
          () => controlPlaneSDK.execute<GroupNotifyChannelCommandOutput>(any()),
        ).thenAnswer(
          (_) async => GroupNotifyChannelCommandOutput(success: true),
        );

        await service.notifyChannel(
          const GroupChannelNotification(
            offerLink: 'offer://group',
            groupDid: 'did:group',
            type: 'call-invite-video',
            memberDid: 'did:bob',
          ),
        );

        final captured =
            verify(
                  () => controlPlaneSDK
                      .execute<GroupNotifyChannelCommandOutput>(captureAny()),
                ).captured.single
                as GroupNotifyChannelCommand;
        expect(captured.memberDid, 'did:bob');
        expect(captured.type, 'call-invite-video');
      });

      test('wraps failure in MessageServiceException', () async {
        when(
          () => controlPlaneSDK.execute<GroupNotifyChannelCommandOutput>(any()),
        ).thenThrow(Exception('boom'));

        expect(
          () => service.notifyChannel(
            const GroupChannelNotification(
              offerLink: 'offer://group',
              groupDid: 'did:group',
              type: 'chat-activity',
            ),
          ),
          throwsA(isA<MessageServiceException>()),
        );
      });
    });
  });
}
