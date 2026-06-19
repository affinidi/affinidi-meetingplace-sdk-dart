import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_chat/src/chat/group/action/remove_member_action.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockChatSDK extends Mock implements GroupMatrixChatSDK {}

class _MockCoreSDK extends Mock implements MeetingPlaceCoreSDK {}

class _MockChatRepository extends Mock implements ChatRepository {}

class _MockLogger extends Mock implements MeetingPlaceChatSDKLogger {}

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
  });

  group('RemoveMemberAction', () {
    late _MockChatSDK chatSDK;
    late _MockCoreSDK coreSDK;
    late _MockChatRepository chatRepository;
    late _MockLogger logger;
    late ChatStream chatStream;
    late Group group;

    setUp(() {
      chatSDK = _MockChatSDK();
      coreSDK = _MockCoreSDK();
      chatRepository = _MockChatRepository();
      logger = _MockLogger();
      chatStream = ChatStream();
      group = _group();

      when(() => chatSDK.coreSDK).thenReturn(coreSDK);
      when(() => chatSDK.chatRepository).thenReturn(chatRepository);
      when(() => chatSDK.chatStream).thenReturn(chatStream);
      when(() => chatSDK.chatId).thenReturn('chat-1');
      when(() => chatSDK.logger).thenReturn(logger);
      when(() => chatSDK.group).thenReturn(group);

      when(
        () => coreSDK.removeMemberFromGroup(
          groupId: any(named: 'groupId'),
          memberDid: any(named: 'memberDid'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => chatRepository.createMessage(any()),
      ).thenAnswer((inv) async => inv.positionalArguments.first as ChatItem);
    });

    test('owner kicks member: calls coreSDK, soft-deletes locally, and '
        'emits ChatMemberDeregisteredEvent', () async {
      when(() => chatSDK.isGroupOwner).thenReturn(true);
      final received = <StreamData>[];
      chatStream.listen(received.add);

      final result = await RemoveMemberAction(
        chatSDK,
        memberDid: 'did:test:bob',
      ).execute();
      await Future<void>.delayed(Duration.zero);

      verify(
        () => coreSDK.removeMemberFromGroup(
          groupId: 'group-1',
          memberDid: 'did:test:bob',
        ),
      ).called(1);

      final bob = result.members.firstWhere((m) => m.did == 'did:test:bob');
      expect(bob.status, GroupMemberStatus.deleted);

      final chatItem =
          verify(
                () => chatRepository.createMessage(captureAny()),
              ).captured.single
              as EventMessage;
      expect(chatItem.data['reason'], GroupMemberLeaveReason.kick.name);

      expect(received.length, 1);
      final event = received.single.event as ChatMemberDeregisteredEvent;
      expect(event.memberDid, 'did:test:bob');
      expect(event.groupDid, 'did:test:group');
    });

    test('non-owner caller: logs error, throws, and does not call '
        'coreSDK', () async {
      when(() => chatSDK.isGroupOwner).thenReturn(false);

      await expectLater(
        () => RemoveMemberAction(chatSDK, memberDid: 'did:test:bob').execute(),
        throwsException,
      );

      verify(() => logger.error(any(), name: 'removeMember')).called(1);
      verifyNever(
        () => coreSDK.removeMemberFromGroup(
          groupId: any(named: 'groupId'),
          memberDid: any(named: 'memberDid'),
        ),
      );
      verifyNever(() => chatRepository.createMessage(any()));
    });

    test('member not in group: throws and does not call coreSDK', () async {
      when(() => chatSDK.isGroupOwner).thenReturn(true);

      await expectLater(
        () => RemoveMemberAction(chatSDK, memberDid: 'did:test:eve').execute(),
        throwsException,
      );

      verifyNever(
        () => coreSDK.removeMemberFromGroup(
          groupId: any(named: 'groupId'),
          memberDid: any(named: 'memberDid'),
        ),
      );
    });

    test('does not mutate local state when coreSDK throws', () async {
      when(() => chatSDK.isGroupOwner).thenReturn(true);
      when(
        () => coreSDK.removeMemberFromGroup(
          groupId: any(named: 'groupId'),
          memberDid: any(named: 'memberDid'),
        ),
      ).thenThrow(Exception('boom'));

      await expectLater(
        () => RemoveMemberAction(chatSDK, memberDid: 'did:test:bob').execute(),
        throwsException,
      );

      final bob = group.members.firstWhere((m) => m.did == 'did:test:bob');
      expect(bob.status, GroupMemberStatus.approved);
      verifyNever(() => chatRepository.createMessage(any()));
    });
  });
}
