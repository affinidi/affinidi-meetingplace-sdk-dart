import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_chat/src/chat/group/event_handler/member_joined_handler.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockCoreSDK extends Mock implements MeetingPlaceCoreSDK {}

class _MockChatRepository extends Mock implements ChatRepository {}

class _FakeChatItem extends Fake implements ChatItem {}

ContactCard _card(String did) =>
    ContactCard(did: did, type: 'human', contactInfo: {'n': did});

Group _groupOwnedBy(String ownerDid) => Group(
  id: 'group-1',
  did: 'did:test:group',
  offerLink: 'offer://test',
  created: DateTime.utc(2026, 1, 1),
  ownerDid: ownerDid,
  publicKey: 'pk',
  members: [GroupMember.admin(did: ownerDid, contactCard: _card(ownerDid))],
);

EventMessage _awaitingMessage(String memberDid) =>
    EventMessage.awaitingGroupMember(
      chatId: 'chat-1',
      groupDid: 'did:test:group',
      memberDid: memberDid,
      memberCard: _card(memberDid).toJson(),
    );

void main() {
  setUpAll(() => registerFallbackValue(_FakeChatItem()));

  group('MemberJoinedHandler', () {
    late _MockCoreSDK coreSDK;
    late _MockChatRepository chatRepository;
    late ChatStream stream;
    late Group group;

    setUp(() {
      coreSDK = _MockCoreSDK();
      chatRepository = _MockChatRepository();
      stream = ChatStream();
      group = _groupOwnedBy('did:test:alice');

      when(
        () => chatRepository.createMessage(any()),
      ).thenAnswer((inv) async => inv.positionalArguments.first as ChatItem);
      when(
        () => chatRepository.updateMesssage(any()),
      ).thenAnswer((inv) async => inv.positionalArguments.first as ChatItem);
      when(() => coreSDK.getGroupById(any())).thenAnswer((_) async => group);
    });

    MemberJoinedHandler buildHandler({String ownDid = 'did:test:alice'}) =>
        MemberJoinedHandler(
          coreSDK: coreSDK,
          chatRepository: chatRepository,
          streamManager: stream,
          chatId: 'chat-1',
          ownDid: ownDid,
          getGroup: () => group,
          setGroup: (g) => group = g,
        );

    test(
      'owner confirms awaiting message and emits joined event message',
      () async {
        final awaiting = _awaitingMessage('did:test:bob');
        when(
          () => chatRepository.listMessages('chat-1'),
        ).thenAnswer((_) async => [awaiting]);

        final received = <StreamData>[];
        stream.listen(received.add);

        await buildHandler().handle(
          IncomingChatEvent(
            type: ChatEventTypes.memberJoined,
            senderDid: 'did:test:bob',
            content: const {},
          ),
        );
        await Future<void>.delayed(Duration.zero);

        expect(awaiting.status, ChatItemStatus.confirmed);
        verify(() => chatRepository.updateMesssage(any())).called(1);
        verify(() => chatRepository.createMessage(any())).called(1);
        expect(received.length, 2);
      },
    );

    test('non-owner ignores the event', () async {
      await buildHandler(ownDid: 'did:test:not-owner').handle(
        IncomingChatEvent(
          type: ChatEventTypes.memberJoined,
          senderDid: 'did:test:bob',
          content: const {},
        ),
      );
      verifyNever(() => chatRepository.listMessages(any()));
    });

    test('null senderDid is a no-op', () async {
      await buildHandler().handle(
        IncomingChatEvent(
          type: ChatEventTypes.memberJoined,
          senderDid: null,
          content: const {},
        ),
      );
      verifyNever(() => chatRepository.listMessages(any()));
    });

    test('returns early when no awaiting message matches', () async {
      when(
        () => chatRepository.listMessages('chat-1'),
      ).thenAnswer((_) async => []);

      await buildHandler().handle(
        IncomingChatEvent(
          type: ChatEventTypes.memberJoined,
          senderDid: 'did:test:bob',
          content: const {},
        ),
      );

      verifyNever(() => chatRepository.createMessage(any()));
      verifyNever(() => chatRepository.updateMesssage(any()));
    });
  });
}
