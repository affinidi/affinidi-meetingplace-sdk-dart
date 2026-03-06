import 'package:meeting_place_core/src/service/channel/channel_service.dart';
import 'package:meeting_place_core/src/service/channel/channel_service_exception.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:meeting_place_core/meeting_place_core.dart';

import 'fixtures/contact_card_fixture.dart';

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

    test('findChannelByDidOrNull returns channel if found', () async {
      when(
        () => repository.findChannelByDid(channel.id),
      ).thenAnswer((_) async => channel);
      final found = await service.findChannelByDidOrNull(channel.id);
      expect(found, equals(channel));
    });

    test('findChannelByDid throws if not found', () async {
      when(
        () => repository.findChannelByDid('notfound'),
      ).thenAnswer((_) async => null);
      expect(
        () => service.findChannelByDid('notfound'),
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

    test(
      'findChannelByOtherPartyPermanentChannelDidOrNull returns channel if found',
      () async {
        when(
          () =>
              repository.findChannelByOtherPartyPermanentChannelDid('otherDid'),
        ).thenAnswer((_) async => channel);
        final found = await service
            .findChannelByOtherPartyPermanentChannelDidOrNull('otherDid');
        expect(found, equals(channel));
      },
    );

    test(
      'findChannelByOtherPartyPermanentChannelDid throws if not found',
      () async {
        when(
          () =>
              repository.findChannelByOtherPartyPermanentChannelDid('notfound'),
        ).thenAnswer((_) async => null);
        expect(
          () => service.findChannelByOtherPartyPermanentChannelDid('notfound'),
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
          otherPartyCard: null,
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
            otherPartyCard: null,
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
            otherPartyCard: null,
          ),
          throwsA(isA<ChannelServiceException>()),
        );
      });
    });

    group('markOobChannelInauguratedForNonConnectionInitiator', () {
      test('succeeds for valid OOB non-initiator', () async {
        final oobChannel = Channel(
          offerLink: 'offer',
          publishOfferDid: 'pubDid',
          mediatorDid: 'medDid',
          status: ChannelStatus.waitingForApproval,
          contactCard: ContactCardFixture.getContactCardFixture(),
          type: ChannelType.oob,
          isConnectionInitiator: false,
        );
        when(() => repository.updateChannel(any())).thenAnswer((_) async {});
        await service.markOobChannelInauguratedForNonConnectionInitiator(
          oobChannel,
          otherPartyPermanentChannelDid: 'otherDid',
          outboundMessageId: 'msgId',
          otherPartyContactCard: null,
        );
        verify(() => repository.updateChannel(oobChannel)).called(1);
        expect(oobChannel.status, ChannelStatus.inaugurated);
      });
      test('throws if not OOB type', () async {
        final notOobChannel = Channel(
          offerLink: 'offer',
          publishOfferDid: 'pubDid',
          mediatorDid: 'medDid',
          status: ChannelStatus.waitingForApproval,
          contactCard: ContactCardFixture.getContactCardFixture(),
          type: ChannelType.individual,
          isConnectionInitiator: false,
        );
        expect(
          () => service.markOobChannelInauguratedForNonConnectionInitiator(
            notOobChannel,
            otherPartyPermanentChannelDid: 'otherDid',
            outboundMessageId: 'msgId',
            otherPartyContactCard: null,
          ),
          throwsA(isA<ChannelServiceException>()),
        );
      });
      test('throws if is initiator', () async {
        final initiatorOobChannel = Channel(
          offerLink: 'offer',
          publishOfferDid: 'pubDid',
          mediatorDid: 'medDid',
          status: ChannelStatus.waitingForApproval,
          contactCard: ContactCardFixture.getContactCardFixture(),
          type: ChannelType.oob,
          isConnectionInitiator: true,
        );
        expect(
          () => service.markOobChannelInauguratedForNonConnectionInitiator(
            initiatorOobChannel,
            otherPartyPermanentChannelDid: 'otherDid',
            outboundMessageId: 'msgId',
            otherPartyContactCard: null,
          ),
          throwsA(isA<ChannelServiceException>()),
        );
      });
      test('throws if not waiting for approval', () async {
        final wrongStatusOobChannel = Channel(
          offerLink: 'offer',
          publishOfferDid: 'pubDid',
          mediatorDid: 'medDid',
          status: ChannelStatus.inaugurated,
          contactCard: ContactCardFixture.getContactCardFixture(),
          type: ChannelType.oob,
          isConnectionInitiator: false,
        );
        expect(
          () => service.markOobChannelInauguratedForNonConnectionInitiator(
            wrongStatusOobChannel,
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
      final now = DateTime.now();
      await service.updateChannelSequence(
        channel,
        sequenceNumber: 99,
        messageSyncMarker: now,
      );
      verify(() => repository.updateChannel(channel)).called(1);
      expect(channel.seqNo, 99);
      expect(channel.messageSyncMarker, now);
    });
  });
}
