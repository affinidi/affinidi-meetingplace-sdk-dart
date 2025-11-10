import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_core/src/service/connection_offer/connection_offer_exception.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'package:meeting_place_core/src/service/connection_offer/connection_offer_service.dart';

// Mock classes
class MockConnectionOfferRepository extends Mock
    implements ConnectionOfferRepository {}

class MockChannelRepository extends Mock implements ChannelRepository {}

void main() {
  late MockConnectionOfferRepository mockOfferRepo;
  late MockChannelRepository mockChannelRepo;
  late ConnectionOfferService service;

  const offerLink = 'test-offer';
  final offer = ConnectionOffer(
    offerName: 'Sample Offer',
    offerLink: offerLink,
    type: ConnectionOfferType.meetingPlaceInvitation,
    mnemonic: 'sample-mnemonic',
    publishOfferDid: 'did:example:publish',
    permanentChannelDid: 'did:example:permanent',
    mediatorDid: 'did:example:mediator',
    oobInvitationMessage: '',
    vCard: VCard.empty(),
    status: ConnectionOfferStatus.published,
    ownedByMe: true,
    createdAt: DateTime.now().toUtc(),
  );

  setUp(() {
    mockOfferRepo = MockConnectionOfferRepository();
    mockChannelRepo = MockChannelRepository();
    service = ConnectionOfferService(
      connectionOfferRepository: mockOfferRepo,
      channelRepository: mockChannelRepo,
    );

    registerFallbackValue(offer);
  });

  group('ensureConnectionOfferIsClaimable', () {
    final channel = Channel(
      offerLink: offerLink,
      publishOfferDid: 'did:key:1234',
      mediatorDid: 'did:key:mediator',
      status: ChannelStatus.inaugurated,
      vCard: VCard.empty(),
      type: ChannelType.individual,
    );

    test('does nothing if offer is null', () async {
      when(() => mockOfferRepo.getConnectionOfferByOfferLink(offerLink))
          .thenAnswer((_) async => null);

      await service.ensureConnectionOfferIsClaimable(offerLink);

      verify(() => mockOfferRepo.getConnectionOfferByOfferLink(offerLink))
          .called(1);
      verifyNever(() => mockChannelRepo.findChannelByDid(any()));
    });

    test('throws ownedByClaimingPartyError if offer is published', () async {
      when(() => mockOfferRepo.getConnectionOfferByOfferLink(offerLink))
          .thenAnswer((_) async => offer);

      expect(
        () => service.ensureConnectionOfferIsClaimable(offerLink),
        throwsA(isA<ConnectionOfferException>().having((e) => e.code.value,
            'code', 'connection_offer_owned_by_claiming_party')),
      );
    });

    test('throws alreadyClaimedByClaimingPartyError if offer is not claimable',
        () async {
      final offerFinalised = offer.copyWith(
        status: ConnectionOfferStatus.accepted,
      );

      when(() => mockOfferRepo.getConnectionOfferByOfferLink(offerLink))
          .thenAnswer((_) async => offerFinalised);

      expect(
        () => service.ensureConnectionOfferIsClaimable(offerLink),
        throwsA(isA<ConnectionOfferException>().having((e) => e.code.value,
            'code', 'connection_offer_already_claimed_by_claiming_party')),
      );
    });

    test(
        'throws alreadyClaimedByClaimingPartyError if channel is of type group and inaugurated',
        () async {
      final groupChannel = Channel(
        offerLink: offerLink,
        publishOfferDid: 'did:key:1234',
        mediatorDid: 'did:key:mediator',
        status: ChannelStatus.inaugurated,
        vCard: VCard.empty(),
        type: ChannelType.group,
      );

      final finalisedOffer =
          offer.copyWith(status: ConnectionOfferStatus.finalised);

      when(() => mockOfferRepo.getConnectionOfferByOfferLink(offerLink))
          .thenAnswer((_) async => finalisedOffer);
      when(() => mockChannelRepo.findChannelByDid(offer.permanentChannelDid!))
          .thenAnswer((_) async => groupChannel);

      expect(
        () => service.ensureConnectionOfferIsClaimable(offerLink),
        throwsA(isA<ConnectionOfferException>().having((e) => e.code.value,
            'code', 'connection_offer_already_claimed_by_claiming_party')),
      );
    });

    test('does nothing if offer is deleted', () async {
      final deletedOffer =
          offer.copyWith(status: ConnectionOfferStatus.deleted);

      when(() => mockOfferRepo.getConnectionOfferByOfferLink(offerLink))
          .thenAnswer((_) async => deletedOffer);
      when(() => mockChannelRepo.findChannelByDid(offer.permanentChannelDid!))
          .thenAnswer((_) async => channel);

      await service.ensureConnectionOfferIsClaimable(offerLink);
    });

    test('does nothing if offer is finalised', () async {
      final finalisedOffer =
          offer.copyWith(status: ConnectionOfferStatus.finalised);

      when(() => mockOfferRepo.getConnectionOfferByOfferLink(offerLink))
          .thenAnswer((_) async => finalisedOffer);
      when(() => mockChannelRepo.findChannelByDid(offer.permanentChannelDid!))
          .thenAnswer((_) async => channel);

      await service.ensureConnectionOfferIsClaimable(offerLink);
    });
  });

  group('markAsDeleted', () {
    test('updates offer and returns it', () async {
      when(() => mockOfferRepo.updateConnectionOffer(any()))
          .thenAnswer((_) async {});

      final result = await service.markAsDeleted(offer);

      expect(result, isNot(equals(offer)));
      verify(() => mockOfferRepo.updateConnectionOffer(result)).called(1);
    });
  });
}
