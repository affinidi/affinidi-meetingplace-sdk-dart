import 'dart:io';

import 'package:meeting_place_core/meeting_place_core.dart' as model;
import 'package:meeting_place_drift_repository/meeting_place_drift_repository.dart';
import 'package:test/test.dart';

void main() {
  group('contactInfoJson persistence', () {
    late Directory tempDirectory;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'meeting_place_drift_repository_test_',
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('channel repository round-trips arbitrary contact info', () async {
      final database = ChannelDatabase(
        databaseName: 'channel.sqlite',
        passphrase: 'test-passphrase',
        directory: tempDirectory,
        inMemory: true,
      );
      addTearDown(database.close);

      final repository = ChannelRepositoryDrift(database: database);
      final channel = model.Channel(
        offerLink: 'offer-link',
        publishOfferDid: 'did:example:publisher',
        mediatorDid: 'did:example:mediator',
        status: model.ChannelStatus.approved,
        type: model.ChannelType.individual,
        isConnectionInitiator: true,
        seqNo: 7,
        contactCard: model.ContactCard(
          did: 'did:example:self',
          type: 'Person',
          contactInfo: {
            'n': {'given': 'Alice', 'surname': 'Jones'},
            'organization': 'Acme',
            'custom': {'tier': 'gold'},
            'photo': 'mxc://server/alice-pic',
          },
        ),
        otherPartyContactCard: model.ContactCard(
          did: 'did:example:other',
          type: 'Person',
          contactInfo: {
            'n': {'given': 'Bob', 'surname': 'Smith'},
            'organization': 'Beta',
            'photo': 'mxc://server/bob-pic',
          },
        ),
        permanentChannelDid: 'did:example:channel-self',
        otherPartyPermanentChannelDid: 'did:example:channel-other',
      );

      await repository.createChannel(channel);

      final stored =
          await repository.findChannelByDid(channel.permanentChannelDid!);

      expect(stored, isNotNull);
      expect(stored!.contactCard!.contactInfo,
          equals(channel.contactCard!.contactInfo));
      expect(
        stored.otherPartyContactCard!.contactInfo,
        equals(channel.otherPartyContactCard!.contactInfo),
      );
      expect(
        stored.contactCard!.contactInfo['photo'],
        equals('mxc://server/alice-pic'),
      );
      expect(
        stored.otherPartyContactCard!.contactInfo['photo'],
        equals('mxc://server/bob-pic'),
      );
    });

    test('connection offer repository round-trips arbitrary contact info',
        () async {
      final database = ConnectionOfferDatabase(
        databaseName: 'connection_offer.sqlite',
        passphrase: 'test-passphrase',
        directory: tempDirectory,
        inMemory: true,
      );
      addTearDown(database.close);

      final repository = ConnectionOfferRepositoryDrift(database: database);
      final connectionOffer = model.ConnectionOffer(
        offerName: 'Offer name',
        offerLink: 'https://example.com/offer',
        mnemonic: 'mnemonic words',
        publishOfferDid: 'did:example:publisher',
        mediatorDid: 'did:example:mediator',
        oobInvitationMessage: 'invitation-message',
        type: model.ConnectionOfferType.meetingPlaceInvitation,
        status: model.ConnectionOfferStatus.published,
        contactCard: model.ContactCard(
          did: 'did:example:contact',
          type: 'Person',
          contactInfo: {
            'organization': 'Acme',
            'photo': 'mxc://server/photo',
            'x-anything': {'value': 'kept'},
          },
        ),
        ownedByMe: true,
        createdAt: DateTime.utc(2026, 1, 1),
      );

      await repository.createConnectionOffer(connectionOffer);

      final stored = await repository.getConnectionOfferByOfferLink(
        connectionOffer.offerLink,
      );

      expect(stored, isNotNull);
      expect(stored!.contactCard.contactInfo,
          equals(connectionOffer.contactCard.contactInfo));
      expect(
        stored.contactCard.contactInfo['photo'],
        equals('mxc://server/photo'),
      );
    });

    test('group repository round-trips arbitrary contact info', () async {
      final database = GroupsDatabase(
        databaseName: 'groups.sqlite',
        passphrase: 'test-passphrase',
        directory: tempDirectory,
        inMemory: true,
      );
      addTearDown(database.close);

      final repository = GroupsRepositoryDrift(database: database);
      final group = model.Group(
        id: 'group-id',
        did: 'did:example:group',
        offerLink: 'group-offer-link',
        created: DateTime.utc(2026, 1, 1),
        members: [
          model.GroupMember(
            did: 'did:example:member',
            dateAdded: DateTime.utc(2026, 1, 2),
            status: model.GroupMemberStatus.approved,
            membershipType: model.GroupMembershipType.admin,
            publicKey: 'public-key',
            contactCard: model.ContactCard(
              did: 'did:example:identity',
              type: 'Person',
              contactInfo: {
                'organization': 'Acme',
                'n': {'given': 'Casey'},
                'photo': 'mxc://server/casey-pic',
              },
            ),
          ),
        ],
      );

      await repository.createGroup(group);

      final stored = await repository.getGroupById(group.id);

      expect(stored, isNotNull);
      expect(
        stored!.members.single.contactCard.contactInfo,
        equals(group.members.single.contactCard.contactInfo),
      );
      expect(
        stored.members.single.contactCard.contactInfo['photo'],
        equals('mxc://server/casey-pic'),
      );
    });
  });
}
