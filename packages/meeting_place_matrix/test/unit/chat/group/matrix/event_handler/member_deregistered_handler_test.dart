import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_matrix/src/chat/group/event_handler/member_deregistered_handler.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockCoreSDK extends Mock implements MeetingPlaceCoreSDK {}

class _MockChatRepository extends Mock implements ChatRepository {}

class _FakeChatItem extends Fake implements ChatItem {}

ContactCard _card(String did) =>
    ContactCard(did: did, type: 'human', contactInfo: {'n': did});

Group _group() => Group(
  id: 'group-1',
  did: 'did:test:group',
  offerLink: 'offer://test',
  created: DateTime.utc(2026, 1, 1),
  ownerDid: 'did:test:alice',
  publicKey: 'pk',
  members: [
    GroupMember.admin(
      did: 'did:test:alice',
      publicKey: 'pk-alice',
      contactCard: _card('did:test:alice'),
    ),
    GroupMember(
      did: 'did:test:bob',
      publicKey: 'pk-bob',
      dateAdded: DateTime.utc(2026, 1, 1),
      status: GroupMemberStatus.approved,
      membershipType: GroupMembershipType.member,
      contactCard: _card('did:test:bob'),
    ),
  ],
);

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeChatItem());
    registerFallbackValue(_group());
  });

  group('MemberDeregisteredHandler', () {
    late _MockCoreSDK coreSDK;
    late _MockChatRepository chatRepository;
    late ChatStream stream;
    late Group group;

    setUp(() {
      coreSDK = _MockCoreSDK();
      chatRepository = _MockChatRepository();
      stream = ChatStream();
      group = _group();

      when(() => coreSDK.updateGroup(any())).thenAnswer((_) async {});
      when(
        () => chatRepository.createMessage(any()),
      ).thenAnswer((inv) async => inv.positionalArguments.first as ChatItem);
    });

    MemberDeregisteredHandler buildHandler() => MemberDeregisteredHandler(
      coreSDK: coreSDK,
      chatRepository: chatRepository,
      streamManager: stream,
      chatId: 'chat-1',
      getGroup: () => group,
      setGroup: (g) => group = g,
    );

    test('marks the matching member deleted and emits '
        'ChatMemberDeregisteredEvent', () async {
      final received = <StreamData>[];
      stream.listen(received.add);

      await buildHandler().handle(
        IncomingChatEvent(
          type: ChatEventTypes.memberLeft,
          senderDid: 'did:test:bob',
          content: const {},
        ),
      );
      await Future<void>.delayed(Duration.zero);

      final bob = group.members.firstWhere((m) => m.did == 'did:test:bob');
      expect(bob.status, GroupMemberStatus.deleted);
      verify(() => coreSDK.updateGroup(any())).called(1);
      final chatItem =
          verify(
                () => chatRepository.createMessage(captureAny()),
              ).captured.single
              as EventMessage;
      expect(chatItem.data['reason'], GroupMemberLeaveReason.leave.name);

      expect(received.length, 1);
      expect(received.single.event, isA<ChatMemberDeregisteredEvent>());
      expect(received.single.chatItem, isA<EventMessage>());
    });

    test('does nothing when senderDid is null', () async {
      final received = <StreamData>[];
      stream.listen(received.add);

      await buildHandler().handle(
        IncomingChatEvent(
          type: ChatEventTypes.memberLeft,
          senderDid: null,
          content: const {},
        ),
      );
      await Future<void>.delayed(Duration.zero);

      verifyNever(() => coreSDK.updateGroup(any()));
      verifyNever(() => chatRepository.createMessage(any()));
      expect(received, isEmpty);
    });

    test(
      'records leave when sender matches the resolved target member',
      () async {
        final received = <StreamData>[];
        stream.listen(received.add);

        await buildHandler().handle(
          IncomingChatEvent(
            type: ChatEventTypes.memberLeft,
            senderDid: 'did:test:bob',
            targetDid: 'did:test:bob',
            content: const {},
          ),
        );
        await Future<void>.delayed(Duration.zero);

        final chatItem =
            verify(
                  () => chatRepository.createMessage(captureAny()),
                ).captured.single
                as EventMessage;
        expect(chatItem.data['reason'], GroupMemberLeaveReason.leave.name);
        expect(received.length, 1);
      },
    );

    test('targetDid takes precedence over senderDid for the kicked '
        'member', () async {
      final received = <StreamData>[];
      stream.listen(received.add);

      await buildHandler().handle(
        IncomingChatEvent(
          type: ChatEventTypes.memberLeft,
          senderDid: 'did:test:alice',
          targetDid: 'did:test:bob',
          content: const {},
        ),
      );
      await Future<void>.delayed(Duration.zero);

      final alice = group.members.firstWhere((m) => m.did == 'did:test:alice');
      final bob = group.members.firstWhere((m) => m.did == 'did:test:bob');
      expect(alice.status, isNot(GroupMemberStatus.deleted));
      expect(bob.status, GroupMemberStatus.deleted);
      verify(() => coreSDK.updateGroup(any())).called(1);
      final chatItem =
          verify(
                () => chatRepository.createMessage(captureAny()),
              ).captured.single
              as EventMessage;
      expect(chatItem.data['reason'], GroupMemberLeaveReason.kick.name);

      expect(received.length, 1);
      final event = received.single.event as ChatMemberDeregisteredEvent;
      expect(event.memberDid, 'did:test:bob');
    });

    test('skips when the member is already deleted (idempotent)', () async {
      group.members.firstWhere((m) => m.did == 'did:test:bob').status =
          GroupMemberStatus.deleted;

      await buildHandler().handle(
        IncomingChatEvent(
          type: ChatEventTypes.memberLeft,
          senderDid: 'did:test:bob',
          content: const {},
        ),
      );

      verifyNever(() => coreSDK.updateGroup(any()));
      verifyNever(() => chatRepository.createMessage(any()));
    });
  });
}
