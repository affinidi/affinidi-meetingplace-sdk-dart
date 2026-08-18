import 'dart:io';

import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart' as model;
import 'package:meeting_place_credentials/meeting_place_credentials.dart'
    as credentials;
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
        final stored =
            await repository.getMessage(chatId: 'chat-1', messageId: 'msg-1')
                as ConciergeMessage;

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
        final stored =
            await repository.getMessage(chatId: 'chat-1', messageId: 'msg-2')
                as ConciergeMessage;

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
        final bookingApproval = ConciergeMessageType.fromJson(
          'bookingApproval',
        );

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

        final updated =
            await repository.getMessage(chatId: 'chat-1', messageId: 'msg-4')
                as ConciergeMessage;

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
        final stored =
            await repository.getMessage(chatId: 'chat-1', messageId: 'evt-1')
                as EventMessage;

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
        final stored =
            await repository.getMessage(chatId: 'chat-1', messageId: 'evt-2')
                as EventMessage;

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

    group('Message attachments', () {
      test(
        'voice attachment metadata round-trips through persistence',
        () async {
          final attachment = VoiceMessageMetadata.buildAttachment(
            id: 'attachment-voice-1',
            base64: 'AAAA',
            durationMs: 11000,
            waveform: const [0, 50, 100, 25],
            filename: 'voice.wav',
            mediaType: 'audio/wav',
            format: 'test-format',
          )..transportId = '\$event-id';

          await repository.createMessage(
            Message(
              chatId: 'chat-1',
              messageId: 'msg-voice',
              senderDid: 'did:example:alice',
              isFromMe: false,
              dateCreated: DateTime.utc(2026),
              status: ChatItemStatus.received,
              value: '',
              attachments: [attachment],
            ),
          );

          final stored = await repository.getMessage(
            chatId: 'chat-1',
            messageId: 'msg-voice',
          );

          expect(stored, isA<Message>());
          final storedAttachment = (stored! as Message).attachments.single;
          expect(VoiceMessageMetadata.isVoice(storedAttachment), isTrue);
          final voice = VoiceMessageMetadata.of(storedAttachment);
          expect(voice?.durationMs, equals(11000));
          expect(voice?.waveform, equals(const [0, 50, 100, 25]));
        },
      );
    });

    group('listMessagesByMediaKind', () {
      // Builds a call-marker attachment inline (mirroring
      // `CallMetadata.toMetadata` from `meeting_place_matrix`) rather than
      // depending on that package from this test.
      ChatAttachment buildCallAttachment(String id) => ChatAttachment(
        id: id,
        metadata: const {
          'media_kind': 'call',
          'call_media_type': 'audio',
          'call_status': 'ended',
          'call_id': 'call-session-id',
        },
      );

      Future<void> seedChat1() async {
        await repository.createMessage(
          Message(
            chatId: 'chat-1',
            messageId: 'text-1',
            senderDid: 'did:example:alice',
            isFromMe: false,
            dateCreated: DateTime.utc(2026, 1, 1),
            status: ChatItemStatus.received,
            value: 'hello',
          ),
        );
        await repository.createMessage(
          Message(
            chatId: 'chat-1',
            messageId: 'text-2',
            senderDid: 'did:example:alice',
            isFromMe: false,
            dateCreated: DateTime.utc(2026, 1, 2),
            status: ChatItemStatus.received,
            value: 'world',
          ),
        );
        await repository.createMessage(
          Message(
            chatId: 'chat-1',
            messageId: 'voice-1',
            senderDid: 'did:example:alice',
            isFromMe: false,
            dateCreated: DateTime.utc(2026, 1, 3),
            status: ChatItemStatus.received,
            value: '',
            attachments: [
              VoiceMessageMetadata.buildAttachment(
                id: 'attachment-voice-1',
                base64: 'AAAA',
                durationMs: 1000,
              ),
            ],
          ),
        );
        await repository.createMessage(
          Message(
            chatId: 'chat-1',
            messageId: 'call-1',
            senderDid: 'did:example:alice',
            isFromMe: false,
            dateCreated: DateTime.utc(2026, 1, 4),
            status: ChatItemStatus.received,
            value: '',
            attachments: [buildCallAttachment('attachment-call-1')],
          ),
        );
        await repository.createMessage(
          Message(
            chatId: 'chat-1',
            messageId: 'call-2',
            senderDid: 'did:example:alice',
            isFromMe: false,
            dateCreated: DateTime.utc(2026, 1, 5),
            status: ChatItemStatus.received,
            value: '',
            attachments: [buildCallAttachment('attachment-call-2')],
          ),
        );
        await repository.createMessage(
          Message(
            chatId: 'chat-1',
            messageId: 'call-3',
            senderDid: 'did:example:alice',
            isFromMe: false,
            dateCreated: DateTime.utc(2026, 1, 6),
            status: ChatItemStatus.received,
            value: '',
            attachments: [buildCallAttachment('attachment-call-3')],
          ),
        );
      }

      test('returns only call messages, most recent first, with empty '
          'reactions and call metadata intact', () async {
        await seedChat1();

        final calls = await repository.listMessagesByMediaKind(
          'chat-1',
          mediaKind: 'call',
        );

        expect(
          calls.map((m) => m.messageId),
          equals(['call-3', 'call-2', 'call-1']),
        );
        for (final call in calls) {
          final message = call as Message;
          expect(message.reactions, isEmpty);
          final attachment = message.attachments.single;
          expect(attachment.metadata?['media_kind'], equals('call'));
        }
      });

      test('limit returns only the most recent call messages', () async {
        await seedChat1();

        final calls = await repository.listMessagesByMediaKind(
          'chat-1',
          mediaKind: 'call',
          limit: 2,
        );

        expect(calls.map((m) => m.messageId), equals(['call-3', 'call-2']));
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

      final stored = await repository.findChannelByDid(
        channel.permanentChannelDid!,
      );

      expect(stored, isNotNull);
      expect(
        stored!.contactCard!.contactInfo,
        equals(channel.contactCard!.contactInfo),
      );
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

    test(
      'connection offer repository round-trips arbitrary contact info',
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
          transport: model.ChannelTransport.didcomm,
        );

        await repository.createConnectionOffer(connectionOffer);

        final stored = await repository.getConnectionOfferByOfferLink(
          connectionOffer.offerLink,
        );

        expect(stored, isNotNull);
        expect(
          stored!.contactCard.contactInfo,
          equals(connectionOffer.contactCard.contactInfo),
        );
        expect(
          stored.contactCard.contactInfo['photo'],
          equals('mxc://server/photo'),
        );
      },
    );

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

    test('addMemberIfAbsent inserts a new member and is a no-op when the '
        'member DID already exists', () async {
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
          model.GroupMember.admin(
            did: 'did:example:owner',
            publicKey: 'pk-owner',
            contactCard: model.ContactCard(
              did: 'did:example:owner',
              type: 'Person',
              contactInfo: const {},
            ),
          ),
        ],
      );
      await repository.createGroup(group);

      final joiner = model.GroupMember.pendingMember(
        did: 'did:example:joiner',
        publicKey: 'pk-joiner',
        contactCard: model.ContactCard(
          did: 'did:example:joiner',
          type: 'Person',
          contactInfo: const {},
        ),
      );

      await repository.addMemberIfAbsent(group.id, joiner);

      final afterFirst = await repository.getGroupById(group.id);
      expect(afterFirst!.members.length, 2);
      final storedJoiner = afterFirst.members.firstWhere(
        (m) => m.did == 'did:example:joiner',
      );
      expect(storedJoiner.status, model.GroupMemberStatus.pendingApproval);

      // Second call with the same DID must not insert a duplicate row, even
      // when the incoming member carries a different status.
      await repository.addMemberIfAbsent(
        group.id,
        joiner.copyWith(status: model.GroupMemberStatus.approved),
      );

      final afterSecond = await repository.getGroupById(group.id);
      expect(afterSecond!.members.length, 2);
      expect(
        afterSecond.members
            .firstWhere((m) => m.did == 'did:example:joiner')
            .status,
        model.GroupMemberStatus.pendingApproval,
      );
    });

    test('updateMemberStatus changes only the targeted member row', () async {
      final database = GroupsDatabase(
        databaseName: 'groups.sqlite',
        passphrase: 'test-passphrase',
        directory: tempDirectory,
        inMemory: true,
      );
      addTearDown(database.close);

      final repository = GroupsRepositoryDrift(database: database);
      model.GroupMember pending(String did) => model.GroupMember.pendingMember(
        did: did,
        publicKey: 'pk-$did',
        contactCard: model.ContactCard(
          did: did,
          type: 'Person',
          contactInfo: const {},
        ),
      );
      final group = model.Group(
        id: 'group-id',
        did: 'did:example:group',
        offerLink: 'group-offer-link',
        created: DateTime.utc(2026, 1, 1),
        members: [pending('did:example:alice'), pending('did:example:bob')],
      );
      await repository.createGroup(group);

      await repository.updateMemberStatus(
        group.id,
        'did:example:alice',
        model.GroupMemberStatus.approved,
      );

      final stored = await repository.getGroupById(group.id);
      expect(
        stored!.members.firstWhere((m) => m.did == 'did:example:alice').status,
        model.GroupMemberStatus.approved,
      );
      // The other member is untouched.
      expect(
        stored.members.firstWhere((m) => m.did == 'did:example:bob').status,
        model.GroupMemberStatus.pendingApproval,
      );
    });

    test('removeMember deletes only the targeted member row', () async {
      final database = GroupsDatabase(
        databaseName: 'groups.sqlite',
        passphrase: 'test-passphrase',
        directory: tempDirectory,
        inMemory: true,
      );
      addTearDown(database.close);

      final repository = GroupsRepositoryDrift(database: database);
      model.GroupMember pending(String did) => model.GroupMember.pendingMember(
        did: did,
        publicKey: 'pk-$did',
        contactCard: model.ContactCard(
          did: did,
          type: 'Person',
          contactInfo: const {},
        ),
      );
      final group = model.Group(
        id: 'group-id',
        did: 'did:example:group',
        offerLink: 'group-offer-link',
        created: DateTime.utc(2026, 1, 1),
        members: [pending('did:example:alice'), pending('did:example:bob')],
      );
      await repository.createGroup(group);

      await repository.removeMember(group.id, 'did:example:alice');

      final stored = await repository.getGroupById(group.id);
      expect(stored!.members.length, 1);
      expect(stored.members.single.did, 'did:example:bob');

      // Removing an absent member is a no-op, not an error.
      await repository.removeMember(group.id, 'did:example:ghost');
      final after = await repository.getGroupById(group.id);
      expect(after!.members.length, 1);
    });

    // ── Regression: lost-update race ────────────────────────────────────────

    test('full-replace updateGroup drops a concurrent member '
        '(documents the hazard the atomic ops fix)', () async {
      // This test characterises the OLD behaviour: two writers each read the
      // same stale member list, append their own member in memory, then each
      // call updateGroup(fullList). Whoever writes last wins; the member
      // added by the first writer is silently dropped.
      final database = GroupsDatabase(
        databaseName: 'groups.sqlite',
        passphrase: 'test-passphrase',
        directory: tempDirectory,
        inMemory: true,
      );
      addTearDown(database.close);

      final repository = GroupsRepositoryDrift(database: database);

      model.GroupMember pending(String did) => model.GroupMember.pendingMember(
        did: did,
        publicKey: 'pk-$did',
        contactCard: model.ContactCard(
          did: did,
          type: 'Person',
          contactInfo: const {},
        ),
      );

      final existingMember = pending('did:example:existing');
      final group = model.Group(
        id: 'group-id',
        did: 'did:example:group',
        offerLink: 'group-offer-link',
        created: DateTime.utc(2026, 1, 1),
        members: [existingMember],
      );
      await repository.createGroup(group);

      // Both writers read the SAME stale snapshot.
      final staleSnapshot = (await repository.getGroupById(group.id))!.members;

      // Writer A (admin approve): reads stale list, appends memberA.
      final memberA = pending('did:example:writer-a-member');
      final listA = [...staleSnapshot, memberA];

      // Writer B (background handler): reads same stale list, appends memberB.
      final memberB = pending('did:example:writer-b-member');
      final listB = [...staleSnapshot, memberB];

      // Sequential writes simulate the race: A writes first, then B
      // overwrites with its own stale-based list (B never saw A's member).
      await repository.updateGroup(group.copyWith(members: listA));
      await repository.updateGroup(group.copyWith(members: listB));

      final result = await repository.getGroupById(group.id);
      final dids = result!.members.map((m) => m.did).toSet();

      // Document the hazard: memberA written by writer A is LOST because
      // writer B's full-replace wiped it out.
      expect(
        dids.contains('did:example:writer-a-member'),
        isFalse,
        reason:
            'full-replace updateGroup loses the member written by writer A '
            'when writer B overwrites with a stale-based list',
      );
    });

    test('atomic single-row ops survive a concurrent approve + addMember '
        '(regression: lost-update race)', () async {
      // Writer A = admin approve  -> updateMemberStatus(existing, approved)
      // Writer B = background handler -> addMemberIfAbsent(newPending)
      //
      // Both ops target different rows / conditions; neither can lose the
      // other's change regardless of scheduling order.
      final database = GroupsDatabase(
        databaseName: 'groups.sqlite',
        passphrase: 'test-passphrase',
        directory: tempDirectory,
        inMemory: true,
      );
      addTearDown(database.close);

      final repository = GroupsRepositoryDrift(database: database);

      model.GroupMember pending(String did) => model.GroupMember.pendingMember(
        did: did,
        publicKey: 'pk-$did',
        contactCard: model.ContactCard(
          did: did,
          type: 'Person',
          contactInfo: const {},
        ),
      );

      // Seed: one existing pending member.
      final existingMember = pending('did:example:existing');
      final group = model.Group(
        id: 'group-id',
        did: 'did:example:group',
        offerLink: 'group-offer-link',
        created: DateTime.utc(2026, 1, 1),
        members: [existingMember],
      );
      await repository.createGroup(group);

      // Interleave both ops deterministically via Future.wait.
      // The single-row ops are independent so any ordering is correct;
      // Future.wait drives both without wall-clock dependency.
      final newMember = pending('did:example:new-joiner');
      await Future.wait([
        // Writer A: approve the existing member.
        repository.updateMemberStatus(
          group.id,
          'did:example:existing',
          model.GroupMemberStatus.approved,
        ),
        // Writer B: add the new pending member.
        repository.addMemberIfAbsent(group.id, newMember),
      ]);

      final result = await repository.getGroupById(group.id);
      expect(result, isNotNull);
      final members = result!.members;

      // Both writes survived: neither clobbered the other.
      expect(
        members.firstWhere((m) => m.did == 'did:example:existing').status,
        model.GroupMemberStatus.approved,
        reason: 'writer A approval must persist after concurrent addMember',
      );
      expect(
        members.any((m) => m.did == 'did:example:new-joiner'),
        isTrue,
        reason:
            'writer B new member must be present after concurrent '
            'approve',
      );
      expect(
        members.firstWhere((m) => m.did == 'did:example:new-joiner').status,
        model.GroupMemberStatus.pendingApproval,
        reason: 'new joiner status must remain pendingApproval',
      );
      expect(members.length, 2);
    });

    test('addMemberIfAbsent produces exactly one row for the same member '
        'DID under concurrent and repeated delivery', () async {
      // Simulates duplicate delivery of the same accept/invite message for
      // one member DID — e.g. a mediator retry racing the original handler
      // run. Every caller passes an identical (groupId, memberDid) pair, and
      // there is still no unique constraint on (group_id, member_did) at the
      // storage level: the guarantee comes from the check-then-insert
      // running inside a transaction on the single underlying connection.
      final database = GroupsDatabase(
        databaseName: 'groups.sqlite',
        passphrase: 'test-passphrase',
        directory: tempDirectory,
        inMemory: true,
      );
      addTearDown(database.close);

      final repository = GroupsRepositoryDrift(database: database);

      final existingMember = model.GroupMember.admin(
        did: 'did:example:owner',
        publicKey: 'pk-owner',
        contactCard: model.ContactCard(
          did: 'did:example:owner',
          type: 'Person',
          contactInfo: const {},
        ),
      );
      final group = model.Group(
        id: 'group-id',
        did: 'did:example:group',
        offerLink: 'group-offer-link',
        created: DateTime.utc(2026, 1, 1),
        members: [existingMember],
      );
      await repository.createGroup(group);

      final duplicateJoiner = model.GroupMember.pendingMember(
        did: 'did:example:duplicate-joiner',
        publicKey: 'pk-duplicate-joiner',
        contactCard: model.ContactCard(
          did: 'did:example:duplicate-joiner',
          type: 'Person',
          contactInfo: const {},
        ),
      );

      // Five concurrent callers race to add the SAME member DID. Future.wait
      // starts every call before any of them yields, so they genuinely
      // interleave at every await point inside addMemberIfAbsent.
      await Future.wait(
        List.generate(
          5,
          (_) => repository.addMemberIfAbsent(group.id, duplicateJoiner),
        ),
      );

      final afterConcurrent = await repository.getGroupById(group.id);
      expect(
        afterConcurrent!.members
            .where((m) => m.did == duplicateJoiner.did)
            .length,
        1,
        reason:
            'concurrent addMemberIfAbsent calls for the same DID must '
            'insert exactly one row',
      );

      // A further repeated call after the concurrent race must still be a
      // no-op.
      await repository.addMemberIfAbsent(group.id, duplicateJoiner);

      final afterRepeat = await repository.getGroupById(group.id);
      expect(
        afterRepeat!.members.where((m) => m.did == duplicateJoiner.did).length,
        1,
        reason: 'a later repeated call must not insert a second row',
      );
    });
  });

  group('RCardRepositoryDrift', () {
    late Directory tempDirectory;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'r_card_repository_drift_test_',
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    RCardDatabase database() => RCardDatabase(
      databaseName: 'r_card.sqlite',
      passphrase: 'test-passphrase',
      directory: tempDirectory,
      inMemory: true,
    );

    credentials.RCard rCard({
      String subjectDid = 'did:example:subject',
      String vcBlob = '{"type":["RelationshipCard"]}',
      String issuerDid = 'did:example:issuer',
      int version = 1,
      String? notes,
    }) => credentials.RCard(
      subjectDid: subjectDid,
      vcBlob: vcBlob,
      issuerDid: issuerDid,
      version: version,
      issuanceDate: DateTime.utc(2026, 1, 1),
      receivedAt: DateTime.utc(2026, 1, 2),
      notes: notes,
    );

    test('upsert persists a new R-Card', () async {
      final db = database();
      addTearDown(db.close);
      final repository = RCardRepositoryDrift(database: db);

      final card = rCard();
      await repository.upsert(card);

      final stored = await repository.getBySubjectDid(card.subjectDid);
      expect(stored, isNotNull);
      expect(stored!.subjectDid, equals(card.subjectDid));
      expect(stored.vcBlob, equals(card.vcBlob));
      expect(stored.issuerDid, equals(card.issuerDid));
      expect(stored.version, equals(1));
    });

    test('upsert increments version when VC content changes', () async {
      final db = database();
      addTearDown(db.close);
      final repository = RCardRepositoryDrift(database: db);

      await repository.upsert(rCard(vcBlob: '{"type":["RelationshipCard"]}'));
      await repository.upsert(
        rCard(vcBlob: '{"type":["RelationshipCard"],"updated":true}'),
      );

      final stored = await repository.getBySubjectDid('did:example:subject');
      expect(stored!.version, equals(2));
    });

    test(
      'upsert does not increment version for identical VC content',
      () async {
        final db = database();
        addTearDown(db.close);
        final repository = RCardRepositoryDrift(database: db);

        final blob = '{"type":["RelationshipCard"]}';
        await repository.upsert(rCard(vcBlob: blob));
        await repository.upsert(rCard(vcBlob: blob));

        final stored = await repository.getBySubjectDid('did:example:subject');
        expect(stored!.version, equals(1));
      },
    );

    test('listAll returns cards ordered by receivedAt descending', () async {
      final db = database();
      addTearDown(db.close);
      final repository = RCardRepositoryDrift(database: db);

      await repository.upsert(
        credentials.RCard(
          subjectDid: 'did:example:alice',
          vcBlob: '{}',
          issuerDid: 'did:example:issuer',
          version: 1,
          issuanceDate: DateTime.utc(2026),
          receivedAt: DateTime.utc(2026, 1, 1),
        ),
      );
      await repository.upsert(
        credentials.RCard(
          subjectDid: 'did:example:bob',
          vcBlob: '{}',
          issuerDid: 'did:example:issuer',
          version: 1,
          issuanceDate: DateTime.utc(2026),
          receivedAt: DateTime.utc(2026, 1, 2),
        ),
      );

      final all = await repository.listAll();
      expect(all.length, equals(2));
      expect(all.first.subjectDid, equals('did:example:bob'));
    });

    test('updateNotes persists and clears notes', () async {
      final db = database();
      addTearDown(db.close);
      final repository = RCardRepositoryDrift(database: db);

      await repository.upsert(rCard());
      await repository.updateNotes('did:example:subject', 'met at conf');

      final withNote = await repository.getBySubjectDid('did:example:subject');
      expect(withNote!.notes, equals('met at conf'));

      await repository.updateNotes('did:example:subject', null);
      final cleared = await repository.getBySubjectDid('did:example:subject');
      expect(cleared!.notes, isNull);
    });

    test('deleteBySubjectDid removes the record', () async {
      final db = database();
      addTearDown(db.close);
      final repository = RCardRepositoryDrift(database: db);

      await repository.upsert(rCard());
      await repository.deleteBySubjectDid('did:example:subject');

      final result = await repository.getBySubjectDid('did:example:subject');
      expect(result, isNull);
    });

    test('getBySubjectDid returns null for unknown DID', () async {
      final db = database();
      addTearDown(db.close);
      final repository = RCardRepositoryDrift(database: db);

      final result = await repository.getBySubjectDid('did:example:unknown');
      expect(result, isNull);
    });
  });

  group('VrcRepositoryDrift', () {
    late Directory tempDirectory;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'vrc_repository_drift_test_',
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    VrcDatabase database() => VrcDatabase(
      databaseName: 'vrc.sqlite',
      passphrase: 'test-passphrase',
      directory: tempDirectory,
      inMemory: true,
    );

    credentials.Vrc vrc({
      String id = 'vrc-1',
      String vcBlob = '{"type":["RelationshipCredential"]}',
      String channelId = 'channel-1',
      String holderDid = 'did:example:holder',
      String issuerDid = 'did:example:issuer',
      DateTime? issuedAt,
      String? credentialFormat,
    }) => credentials.Vrc(
      id: id,
      vcBlob: vcBlob,
      referenceId: channelId,
      holderDid: holderDid,
      issuerDid: issuerDid,
      issuedAt: issuedAt ?? DateTime.utc(2026, 1, 1),
      credentialFormat: credentialFormat,
    );

    test('upsert persists a new VRC', () async {
      final db = database();
      addTearDown(db.close);
      final repository = VrcRepositoryDrift(database: db);

      await repository.upsert(vrc());

      final stored = await repository.getById('vrc-1');
      expect(stored, isNotNull);
      expect(stored!.id, equals('vrc-1'));
      expect(stored.referenceId, equals('channel-1'));
      expect(stored.holderDid, equals('did:example:holder'));
      expect(stored.issuerDid, equals('did:example:issuer'));
    });

    test(
      'upsert updates metadata without changing vcBlob for same id',
      () async {
        final db = database();
        addTearDown(db.close);
        final repository = VrcRepositoryDrift(database: db);

        await repository.upsert(vrc(channelId: 'channel-old'));
        await repository.upsert(vrc(channelId: 'channel-new'));

        final stored = await repository.getById('vrc-1');
        expect(stored!.referenceId, equals('channel-new'));
      },
    );

    test('upsert replaces row when vcBlob changes', () async {
      final db = database();
      addTearDown(db.close);
      final repository = VrcRepositoryDrift(database: db);

      await repository.upsert(
        vrc(vcBlob: '{"type":["RelationshipCredential"]}'),
      );
      await repository.upsert(
        vrc(vcBlob: '{"type":["RelationshipCredential"],"updated":true}'),
      );

      final stored = await repository.getById('vrc-1');
      expect(stored!.vcBlob, contains('updated'));
    });

    test('listAll returns all VRCs ordered by issuedAt descending', () async {
      final db = database();
      addTearDown(db.close);
      final repository = VrcRepositoryDrift(database: db);

      await repository.upsert(
        vrc(id: 'vrc-old', issuedAt: DateTime.utc(2025, 1, 1)),
      );
      await repository.upsert(
        vrc(id: 'vrc-new', issuedAt: DateTime.utc(2026, 1, 1)),
      );

      final all = await repository.listAll();
      expect(all.length, equals(2));
      expect(all.first.id, equals('vrc-new'));
    });

    test('listByHolderDid returns only matching VRCs', () async {
      final db = database();
      addTearDown(db.close);
      final repository = VrcRepositoryDrift(database: db);

      await repository.upsert(vrc(id: 'vrc-a', holderDid: 'did:example:alice'));
      await repository.upsert(vrc(id: 'vrc-b', holderDid: 'did:example:bob'));

      final aliceVrcs = await repository.listByHolderDid('did:example:alice');
      expect(aliceVrcs, hasLength(1));
      expect(aliceVrcs.first.id, equals('vrc-a'));
    });

    test('countByHolderDid returns correct count', () async {
      final db = database();
      addTearDown(db.close);
      final repository = VrcRepositoryDrift(database: db);

      await repository.upsert(vrc(id: 'vrc-a', holderDid: 'did:example:alice'));
      await repository.upsert(vrc(id: 'vrc-b', holderDid: 'did:example:alice'));
      await repository.upsert(vrc(id: 'vrc-c', holderDid: 'did:example:bob'));

      expect(await repository.countByHolderDid('did:example:alice'), equals(2));
      expect(await repository.countByHolderDid('did:example:bob'), equals(1));
    });

    test('deleteById removes the record', () async {
      final db = database();
      addTearDown(db.close);
      final repository = VrcRepositoryDrift(database: db);

      await repository.upsert(vrc());
      await repository.deleteById('vrc-1');

      expect(await repository.getById('vrc-1'), isNull);
    });

    test('getById returns null for unknown id', () async {
      final db = database();
      addTearDown(db.close);
      final repository = VrcRepositoryDrift(database: db);

      expect(await repository.getById('does-not-exist'), isNull);
    });

    test('watchAll emits after upsert', () async {
      final db = database();
      addTearDown(db.close);
      final repository = VrcRepositoryDrift(database: db);

      final emitted = <List<credentials.Vrc>>[];
      final sub = repository.watchAll().listen(emitted.add);

      await repository.upsert(vrc());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(emitted.last, hasLength(1));
      await sub.cancel();
    });
  });
}
