import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_chat/src/chat/group/event_handler/group_deletion_handler.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockCoreSDK extends Mock implements MeetingPlaceCoreSDK {}

class _MockChatRepository extends Mock implements ChatRepository {}

class _FakeChatItem extends Fake implements ChatItem {}

ContactCard _card() => ContactCard(
  did: 'did:test:owner',
  type: 'human',
  contactInfo: const {'n': 'Owner'},
);

Group _group() => Group(
  id: 'group-1',
  did: 'did:test:group',
  offerLink: 'offer://test',
  created: DateTime.utc(2026, 1, 1),
  ownerDid: 'did:test:owner',
  publicKey: 'pk',
  members: [
    GroupMember.admin(
      did: 'did:test:owner',
      publicKey: 'pk',
      contactCard: _card(),
    ),
  ],
);

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeChatItem());
    registerFallbackValue(_group());
  });

  group('GroupDeletionHandler', () {
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

    GroupDeletionHandler buildHandler() => GroupDeletionHandler(
      coreSDK: coreSDK,
      chatRepository: chatRepository,
      streamManager: stream,
      chatId: 'chat-1',
      getGroup: () => group,
      setGroup: (g) => group = g,
    );

    test('marks group deleted, persists event message, emits stream items',
        () async {
      final received = <StreamData>[];
      stream.listen(received.add);

      await buildHandler().handle(
        IncomingChatEvent(
          type: ChatEventTypes.groupDeletion,
          senderDid: 'did:test:owner',
          content: const {},
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(group.isDeleted, isTrue);
      verify(() => coreSDK.updateGroup(any())).called(1);
      verify(() => chatRepository.createMessage(any())).called(1);

      expect(received.length, 2);
      expect(received[0].chatItem, isA<EventMessage>());
      final emitted = received[1].event;
      expect(emitted, isA<ChatGroupDeletedEvent>());
      expect((emitted as ChatGroupDeletedEvent).groupDid, group.did);
    });

    test('skips persistence when group is already deleted', () async {
      group.markAsDeleted();
      final received = <StreamData>[];
      stream.listen(received.add);

      await buildHandler().handle(
        IncomingChatEvent(
          type: ChatEventTypes.groupDeletion,
          senderDid: 'did:test:owner',
          content: const {},
        ),
      );
      await Future<void>.delayed(Duration.zero);

      verifyNever(() => coreSDK.updateGroup(any()));
      verifyNever(() => chatRepository.createMessage(any()));
      // Still emits the typed event so the UI can react.
      expect(received.length, 1);
      expect(received.single.event, isA<ChatGroupDeletedEvent>());
    });
  });
}
