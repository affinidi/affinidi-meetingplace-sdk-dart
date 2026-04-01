import 'dart:io';

import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart' as model;
import 'package:meeting_place_drift_repository/meeting_place_drift_repository.dart';
import 'package:test/test.dart';

ChatItemsDatabase _inMemoryDatabase() => ChatItemsDatabase(
      databaseName: 'test.db',
      passphrase: 'test-passphrase',
      directory: Directory.systemTemp,
      inMemory: true,
      lazy: false,
    );

void main() {
  group('ChatItemsRepositoryDrift', () {
    late ChatItemsDatabase database;
    late ChatItemsRepositoryDrift repository;

    setUp(() {
      database = _inMemoryDatabase();
      repository = ChatItemsRepositoryDrift(database: database);
    });

    tearDown(() => database.close());

    group('ConciergeMessage', () {
      test('persists and retrieves a built-in concierge type', () async {
        final message = ConciergeMessage(
          chatId: 'chat-1',
          messageId: 'msg-1',
          senderDid: 'did:example:alice',
          isFromMe: false,
          dateCreated: DateTime.utc(2026),
          status: ChatItemStatus.userInput,
          conciergeType: ConciergeMessageType.permissionToJoinGroup,
          data: {'groupId': 'group-42'},
        );

        await repository.createMessage(message);
        final stored = await repository.getMessage(
          chatId: 'chat-1',
          messageId: 'msg-1',
        ) as ConciergeMessage;

        expect(
          stored.conciergeType,
          equals(ConciergeMessageType.permissionToJoinGroup),
        );
        expect(stored.data['groupId'], equals('group-42'));
      });

      test('persists and retrieves a custom concierge type', () async {
        final meetingRequest = ConciergeMessageType.fromJson('meetingRequest');

        final message = ConciergeMessage(
          chatId: 'chat-1',
          messageId: 'msg-2',
          senderDid: 'did:example:bot',
          isFromMe: false,
          dateCreated: DateTime.utc(2026),
          status: ChatItemStatus.userInput,
          conciergeType: meetingRequest,
          data: {'scheduledAt': '2026-05-01T10:00:00Z'},
        );

        await repository.createMessage(message);
        final stored = await repository.getMessage(
          chatId: 'chat-1',
          messageId: 'msg-2',
        ) as ConciergeMessage;

        expect(stored.conciergeType, equals(meetingRequest));
        expect(stored.conciergeType.value, equals('meetingRequest'));
        expect(stored.data['scheduledAt'], equals('2026-05-01T10:00:00Z'));
      });

      test('listMessages returns custom concierge type', () async {
        final supportTicket = ConciergeMessageType.fromJson('supportTicket');

        await repository.createMessage(
          ConciergeMessage(
            chatId: 'chat-1',
            messageId: 'msg-3',
            senderDid: 'did:example:support',
            isFromMe: false,
            dateCreated: DateTime.utc(2026),
            status: ChatItemStatus.userInput,
            conciergeType: supportTicket,
            data: {'ticketId': 'TKT-999'},
          ),
        );

        final messages = await repository.listMessages('chat-1');
        final result = messages.whereType<ConciergeMessage>().first;

        expect(result.conciergeType, equals(supportTicket));
      });

      test('updates status while preserving a custom concierge type', () async {
        final bookingApproval =
            ConciergeMessageType.fromJson('bookingApproval');

        final message = ConciergeMessage(
          chatId: 'chat-1',
          messageId: 'msg-4',
          senderDid: 'did:example:alice',
          isFromMe: false,
          dateCreated: DateTime.utc(2026),
          status: ChatItemStatus.userInput,
          conciergeType: bookingApproval,
          data: {},
        );

        await repository.createMessage(message);
        message.status = ChatItemStatus.confirmed;
        await repository.updateMesssage(message);

        final updated = await repository.getMessage(
          chatId: 'chat-1',
          messageId: 'msg-4',
        ) as ConciergeMessage;

        expect(updated.status, equals(ChatItemStatus.confirmed));
        expect(updated.conciergeType, equals(bookingApproval));
      });
    });

    group('EventMessage', () {
      test('persists and retrieves a built-in event type', () async {
        final message = EventMessage(
          chatId: 'chat-1',
          messageId: 'evt-1',
          senderDid: 'did:example:group',
          isFromMe: false,
          dateCreated: DateTime.utc(2026),
          status: ChatItemStatus.received,
          eventType: EventMessageType.groupMemberJoinedGroup,
          data: {'memberDid': 'did:example:bob'},
        );

        await repository.createMessage(message);
        final stored = await repository.getMessage(
          chatId: 'chat-1',
          messageId: 'evt-1',
        ) as EventMessage;

        expect(
          stored.eventType,
          equals(EventMessageType.groupMemberJoinedGroup),
        );
      });

      test('persists and retrieves a custom event type', () async {
        final fileShared = EventMessageType.fromJson('fileShared');

        final message = EventMessage(
          chatId: 'chat-1',
          messageId: 'evt-2',
          senderDid: 'did:example:alice',
          isFromMe: true,
          dateCreated: DateTime.utc(2026),
          status: ChatItemStatus.received,
          eventType: fileShared,
          data: {'filename': 'report.pdf', 'size': 204800},
        );

        await repository.createMessage(message);
        final stored = await repository.getMessage(
          chatId: 'chat-1',
          messageId: 'evt-2',
        ) as EventMessage;

        expect(stored.eventType, equals(fileShared));
        expect(stored.eventType.value, equals('fileShared'));
        expect(stored.data['filename'], equals('report.pdf'));
      });

      test('listMessages returns custom event type', () async {
        final callStarted = EventMessageType.fromJson('callStarted');

        await repository.createMessage(
          EventMessage(
            chatId: 'chat-1',
            messageId: 'evt-3',
            senderDid: 'did:example:alice',
            isFromMe: true,
            dateCreated: DateTime.utc(2026),
            status: ChatItemStatus.received,
            eventType: callStarted,
            data: {},
          ),
        );

        final messages = await repository.listMessages('chat-1');
        final result = messages.whereType<EventMessage>().first;

        expect(result.eventType, equals(callStarted));
      });
    });
  });

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
          },
        ),
        otherPartyContactCard: model.ContactCard(
          did: 'did:example:other',
          type: 'Person',
          contactInfo: {
            'n': {'given': 'Bob', 'surname': 'Smith'},
            'organization': 'Beta',
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
    });
  });
}
