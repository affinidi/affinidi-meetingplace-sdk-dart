import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_core/src/service/channel/channel_service.dart';
import 'package:meeting_place_core/src/service/channel/channel_service_exception.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../fixtures/contact_card_fixture.dart';

class MockChannelRepository extends Mock implements ChannelRepository {}

void main() {
  group('ChannelService', () {
    late MockChannelRepository repository;
    late ChannelService service;
    late Channel channel;

    setUp(() {
      repository = MockChannelRepository();
      service = ChannelService(channelRepository: repository);
      channel = Channel(
        offerLink: 'offer',
        publishOfferDid: 'pubDid',
        mediatorDid: 'medDid',
        status: ChannelStatus.waitingForApproval,
        contactCard: ContactCardFixture.getContactCardFixture(),
        type: ChannelType.individual,
        isConnectionInitiator: true,
      );
      registerFallbackValue(channel);
    });

    test('persistChannel calls createChannel', () async {
      when(() => repository.createChannel(any())).thenAnswer((_) async {});
      await service.persistChannel(channel);
      verify(() => repository.createChannel(channel)).called(1);
    });

    test('findChannelByDid returns channel if found', () async {
      when(
        () => repository.findChannelByDid(channel.id),
      ).thenAnswer((_) async => channel);
      final found = await service.findChannelByDid(channel.id);
      expect(found, equals(channel));
    });

    test('getChannelByDid throws if not found', () async {
      when(
        () => repository.findChannelByDid('notfound'),
      ).thenAnswer((_) async => null);
      expect(
        () => service.getChannelByDid('notfound'),
        throwsA(isA<ChannelServiceException>()),
      );
    });

    test('updateChannel calls updateChannel', () async {
      when(() => repository.updateChannel(any())).thenAnswer((_) async {});
      await service.updateChannel(channel);
      verify(() => repository.updateChannel(channel)).called(1);
    });

    test('deleteChannel calls deleteChannel', () async {
      when(() => repository.deleteChannel(any())).thenAnswer((_) async {});
      await service.deleteChannel(channel);
      verify(() => repository.deleteChannel(channel)).called(1);
    });

    test('findChannelByOtherPartyPermanentChannelDid returns channel if '
        'found', () async {
      when(
        () => repository.findChannelByOtherPartyPermanentChannelDid('otherDid'),
      ).thenAnswer((_) async => channel);
      final found = await service.findChannelByOtherPartyPermanentChannelDid(
        'otherDid',
      );
      expect(found, equals(channel));
    });

    test(
      'getChannelByOtherPartyPermanentChannelDid throws if not found',
      () async {
        when(
          () =>
              repository.findChannelByOtherPartyPermanentChannelDid('notfound'),
        ).thenAnswer((_) async => null);
        expect(
          () => service.getChannelByOtherPartyPermanentChannelDid('notfound'),
          throwsA(isA<ChannelServiceException>()),
        );
      },
    );

    group('markChannelApprovedForConnectionInitiator', () {
      test('succeeds for valid initiator', () async {
        final initiatorChannel = Channel(
          offerLink: 'offer',
          publishOfferDid: 'pubDid',
          mediatorDid: 'medDid',
          status: ChannelStatus.waitingForApproval,
          contactCard: ContactCardFixture.getContactCardFixture(),
          type: ChannelType.individual,
          isConnectionInitiator: true,
        );
        when(() => repository.updateChannel(any())).thenAnswer((_) async {});
        await service.markChannelApprovedForConnectionInitiator(
          initiatorChannel,
          permanentChannelDid: 'permanent',
          otherPartyPermanentChannelDid: 'other',
          notificationToken: 'token',
        );
        verify(() => repository.updateChannel(initiatorChannel)).called(1);
        expect(initiatorChannel.status, ChannelStatus.approved);
      });
      test('throws if group type', () async {
        final groupChannel = Channel(
          offerLink: 'offer',
          publishOfferDid: 'pubDid',
          mediatorDid: 'medDid',
          status: ChannelStatus.waitingForApproval,
          contactCard: ContactCardFixture.getContactCardFixture(),
          type: ChannelType.group,
          isConnectionInitiator: true,
        );
        expect(
          () => service.markChannelApprovedForConnectionInitiator(
            groupChannel,
            permanentChannelDid: 'permanent',
            otherPartyPermanentChannelDid: 'other',
            notificationToken: 'token',
          ),
          throwsA(isA<ChannelServiceException>()),
        );
      });
      test('throws if not initiator', () async {
        final nonInitiatorChannel = Channel(
          offerLink: 'offer',
          publishOfferDid: 'pubDid',
          mediatorDid: 'medDid',
          status: ChannelStatus.waitingForApproval,
          contactCard: ContactCardFixture.getContactCardFixture(),
          type: ChannelType.individual,
          isConnectionInitiator: false,
        );
        expect(
          () => service.markChannelApprovedForConnectionInitiator(
            nonInitiatorChannel,
            permanentChannelDid: 'permanent',
            otherPartyPermanentChannelDid: 'other',
            notificationToken: 'token',
          ),
          throwsA(isA<ChannelServiceException>()),
        );
      });
      test('throws if not waiting for approval', () async {
        final wrongStatusChannel = Channel(
          offerLink: 'offer',
          publishOfferDid: 'pubDid',
          mediatorDid: 'medDid',
          status: ChannelStatus.inaugurated,
          contactCard: ContactCardFixture.getContactCardFixture(),
          type: ChannelType.individual,
          isConnectionInitiator: true,
        );
        expect(
          () => service.markChannelApprovedForConnectionInitiator(
            wrongStatusChannel,
            permanentChannelDid: 'permanent',
            otherPartyPermanentChannelDid: 'other',
            notificationToken: 'token',
          ),
          throwsA(isA<ChannelServiceException>()),
        );
      });
    });

    group('markChannelInauguratedForConnectionInitiator', () {
      test('succeeds for valid initiator', () async {
        final initiatorChannel = Channel(
          offerLink: 'offer',
          publishOfferDid: 'pubDid',
          mediatorDid: 'medDid',
          status: ChannelStatus.waitingForApproval,
          contactCard: ContactCardFixture.getContactCardFixture(),
          type: ChannelType.individual,
          isConnectionInitiator: true,
        );
        when(() => repository.updateChannel(any())).thenAnswer((_) async {});
        await service.markChannelInauguratedForConnectionInitiator(
          initiatorChannel,
          otherPartyNotificationToken: 'token',
        );
        verify(() => repository.updateChannel(initiatorChannel)).called(1);
        expect(initiatorChannel.status, ChannelStatus.inaugurated);
      });
      test('throws if group type', () async {
        final groupChannel = Channel(
          offerLink: 'offer',
          publishOfferDid: 'pubDid',
          mediatorDid: 'medDid',
          status: ChannelStatus.waitingForApproval,
          contactCard: ContactCardFixture.getContactCardFixture(),
          type: ChannelType.group,
          isConnectionInitiator: true,
        );
        expect(
          () => service.markChannelInauguratedForConnectionInitiator(
            groupChannel,
            otherPartyNotificationToken: 'token',
          ),
          throwsA(isA<ChannelServiceException>()),
        );
      });
      test('throws if not initiator', () async {
        final nonInitiatorChannel = Channel(
          offerLink: 'offer',
          publishOfferDid: 'pubDid',
          mediatorDid: 'medDid',
          status: ChannelStatus.waitingForApproval,
          contactCard: ContactCardFixture.getContactCardFixture(),
          type: ChannelType.individual,
          isConnectionInitiator: false,
        );
        expect(
          () => service.markChannelInauguratedForConnectionInitiator(
            nonInitiatorChannel,
            otherPartyNotificationToken: 'token',
          ),
          throwsA(isA<ChannelServiceException>()),
        );
      });
    });

    group('markChannelInauguratedForNonConnectionInitiator', () {
      test('succeeds for valid non-initiator', () async {
        final nonInitiatorChannel = Channel(
          offerLink: 'offer',
          publishOfferDid: 'pubDid',
          mediatorDid: 'medDid',
          status: ChannelStatus.waitingForApproval,
          contactCard: ContactCardFixture.getContactCardFixture(),
          type: ChannelType.individual,
          isConnectionInitiator: false,
        );
        when(() => repository.updateChannel(any())).thenAnswer((_) async {});
        await service.markChannelInauguratedForNonConnectionInitiator(
          nonInitiatorChannel,
          notificationToken: 'token',
          otherPartyNotificationToken: 'otherToken',
          otherPartyPermanentChannelDid: 'otherDid',
          outboundMessageId: 'msgId',
          otherPartyContactCard: null,
        );
        verify(() => repository.updateChannel(nonInitiatorChannel)).called(1);
        expect(nonInitiatorChannel.status, ChannelStatus.inaugurated);
      });
      test('throws if not individual type', () async {
        final groupChannel = Channel(
          offerLink: 'offer',
          publishOfferDid: 'pubDid',
          mediatorDid: 'medDid',
          status: ChannelStatus.waitingForApproval,
          contactCard: ContactCardFixture.getContactCardFixture(),
          type: ChannelType.group,
          isConnectionInitiator: false,
        );
        expect(
          () => service.markChannelInauguratedForNonConnectionInitiator(
            groupChannel,
            notificationToken: 'token',
            otherPartyNotificationToken: 'otherToken',
            otherPartyPermanentChannelDid: 'otherDid',
            outboundMessageId: 'msgId',
            otherPartyContactCard: null,
          ),
          throwsA(isA<ChannelServiceException>()),
        );
      });
      test('throws if is initiator', () async {
        final initiatorChannel = Channel(
          offerLink: 'offer',
          publishOfferDid: 'pubDid',
          mediatorDid: 'medDid',
          status: ChannelStatus.waitingForApproval,
          contactCard: ContactCardFixture.getContactCardFixture(),
          type: ChannelType.individual,
          isConnectionInitiator: true,
        );
        expect(
          () => service.markChannelInauguratedForNonConnectionInitiator(
            initiatorChannel,
            notificationToken: 'token',
            otherPartyNotificationToken: 'otherToken',
            otherPartyPermanentChannelDid: 'otherDid',
            outboundMessageId: 'msgId',
            otherPartyContactCard: null,
          ),
          throwsA(isA<ChannelServiceException>()),
        );
      });
    });

    group('markDirectConnectionChannelInauguratedForNonConnectionInitiator', () {
      test('succeeds for valid direct connection non-initiator', () async {
        final directConnectionChannel = Channel(
          offerLink: 'offer',
          publishOfferDid: 'pubDid',
          mediatorDid: 'medDid',
          status: ChannelStatus.waitingForApproval,
          contactCard: ContactCardFixture.getContactCardFixture(),
          type: ChannelType.directConnection,
          isConnectionInitiator: false,
        );
        when(() => repository.updateChannel(any())).thenAnswer((_) async {});
        await service
            .markDirectConnectionChannelInauguratedForNonConnectionInitiator(
              directConnectionChannel,
              otherPartyPermanentChannelDid: 'otherDid',
              outboundMessageId: 'msgId',
              otherPartyContactCard: null,
            );
        verify(
          () => repository.updateChannel(directConnectionChannel),
        ).called(1);
        expect(directConnectionChannel.status, ChannelStatus.inaugurated);
      });
      test('throws if not direct connection type', () async {
        final notDirectConnectionChannel = Channel(
          offerLink: 'offer',
          publishOfferDid: 'pubDid',
          mediatorDid: 'medDid',
          status: ChannelStatus.waitingForApproval,
          contactCard: ContactCardFixture.getContactCardFixture(),
          type: ChannelType.individual,
          isConnectionInitiator: false,
        );
        expect(
          () => service
              .markDirectConnectionChannelInauguratedForNonConnectionInitiator(
                notDirectConnectionChannel,
                otherPartyPermanentChannelDid: 'otherDid',
                outboundMessageId: 'msgId',
                otherPartyContactCard: null,
              ),
          throwsA(isA<ChannelServiceException>()),
        );
      });
      test('throws if is initiator', () async {
        final initiatorDirectConnectionChannel = Channel(
          offerLink: 'offer',
          publishOfferDid: 'pubDid',
          mediatorDid: 'medDid',
          status: ChannelStatus.waitingForApproval,
          contactCard: ContactCardFixture.getContactCardFixture(),
          type: ChannelType.directConnection,
          isConnectionInitiator: true,
        );
        expect(
          () => service
              .markDirectConnectionChannelInauguratedForNonConnectionInitiator(
                initiatorDirectConnectionChannel,
                otherPartyPermanentChannelDid: 'otherDid',
                outboundMessageId: 'msgId',
                otherPartyContactCard: null,
              ),
          throwsA(isA<ChannelServiceException>()),
        );
      });
      test('throws if not waiting for approval', () async {
        final wrongStatusDirectConnectionChannel = Channel(
          offerLink: 'offer',
          publishOfferDid: 'pubDid',
          mediatorDid: 'medDid',
          status: ChannelStatus.inaugurated,
          contactCard: ContactCardFixture.getContactCardFixture(),
          type: ChannelType.directConnection,
          isConnectionInitiator: false,
        );
        expect(
          () => service
              .markDirectConnectionChannelInauguratedForNonConnectionInitiator(
                wrongStatusDirectConnectionChannel,
                otherPartyPermanentChannelDid: 'otherDid',
                outboundMessageId: 'msgId',
                otherPartyContactCard: null,
              ),
          throwsA(isA<ChannelServiceException>()),
        );
      });
    });

    group('markGroupChannelInauguratedFromWaitingForApproval', () {
      test('succeeds for valid group', () async {
        final groupChannel = Channel(
          offerLink: 'offer',
          publishOfferDid: 'pubDid',
          mediatorDid: 'medDid',
          status: ChannelStatus.waitingForApproval,
          contactCard: ContactCardFixture.getContactCardFixture(),
          type: ChannelType.group,
          isConnectionInitiator: false,
        );
        when(() => repository.updateChannel(any())).thenAnswer((_) async {});
        await service.markGroupChannelInauguratedFromWaitingForApproval(
          groupChannel,
          notificationToken: 'token',
          otherPartyPermanentChannelDid: 'otherDid',
          sequenceNumber: 42,
        );
        verify(() => repository.updateChannel(groupChannel)).called(1);
        expect(groupChannel.status, ChannelStatus.inaugurated);
      });
      test('throws if not group type', () async {
        final notGroupChannel = Channel(
          offerLink: 'offer',
          publishOfferDid: 'pubDid',
          mediatorDid: 'medDid',
          status: ChannelStatus.waitingForApproval,
          contactCard: ContactCardFixture.getContactCardFixture(),
          type: ChannelType.individual,
          isConnectionInitiator: false,
        );
        expect(
          () => service.markGroupChannelInauguratedFromWaitingForApproval(
            notGroupChannel,
            notificationToken: 'token',
            otherPartyPermanentChannelDid: 'otherDid',
            sequenceNumber: 42,
          ),
          throwsA(isA<ChannelServiceException>()),
        );
      });
      test('throws if not waiting for approval', () async {
        final wrongStatusGroupChannel = Channel(
          offerLink: 'offer',
          publishOfferDid: 'pubDid',
          mediatorDid: 'medDid',
          status: ChannelStatus.inaugurated,
          contactCard: ContactCardFixture.getContactCardFixture(),
          type: ChannelType.group,
          isConnectionInitiator: false,
        );
        expect(
          () => service.markGroupChannelInauguratedFromWaitingForApproval(
            wrongStatusGroupChannel,
            notificationToken: 'token',
            otherPartyPermanentChannelDid: 'otherDid',
            sequenceNumber: 42,
          ),
          throwsA(isA<ChannelServiceException>()),
        );
      });
    });

    test('updateChannelSequence updates seqNo and messageSyncMarker', () async {
      when(() => repository.updateChannel(any())).thenAnswer((_) async {});
      const marker = '2026-06-18T12:00:00.000Z';
      await service.updateChannelSequence(
        channel,
        sequenceNumber: 99,
        messageSyncMarker: marker,
      );
      verify(() => repository.updateChannel(channel)).called(1);
      expect(channel.seqNo, 99);
      expect(channel.messageSyncMarker, marker);
    });
  });
}
