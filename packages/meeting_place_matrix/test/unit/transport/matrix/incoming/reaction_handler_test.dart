import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_matrix/src/transport/matrix/incoming/incoming_reaction_state_store.dart';
import 'package:meeting_place_matrix/src/transport/matrix/incoming/reaction_handler.dart';
import 'package:meeting_place_matrix/meeting_place_matrix.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockChatRepository extends Mock implements ChatRepository {}

const _chatId = 'chat-1';
const _aliceDid = 'did:test:alice';
const _bobDid = 'did:test:bob';

MatrixRoomEvent _reactionEvent({
  required String targetEventId,
  String reaction = '👍',
  String id = r'$reaction-1',
}) => MatrixRoomEvent(
  id: id,
  type: 'm.reaction',
  senderDid: _bobDid,
  roomId: '!room:server',
  content: {
    'm.relates_to': {
      'rel_type': 'm.annotation',
      'event_id': targetEventId,
      'key': reaction,
    },
  },
  timestamp: DateTime.utc(2026, 1, 1, 12),
);

Message _message({
  String messageId = 'local-1',
  String? transportId = r'$server-1',
  bool isDeleted = false,
  bool isDeletedLocally = false,
  List<MessageReaction> reactions = const [],
}) => Message(
  chatId: _chatId,
  messageId: messageId,
  senderDid: _aliceDid,
  value: 'hello',
  isFromMe: true,
  dateCreated: DateTime.utc(2026, 1, 1, 11),
  status: ChatItemStatus.sent,
  transportId: transportId,
  isDeleted: isDeleted,
  isDeletedLocally: isDeletedLocally,
  reactions: reactions,
);

void main() {
  late _MockChatRepository repo;
  late ChatStream stream;
  late IncomingReactionStateStore reactionStore;
  late ReactionHandler handler;
  late List<StreamData> emitted;
  late List<ChatItem> storedItems;
  late Map<String, String> eventIdMap;

  setUpAll(() {
    registerFallbackValue(
      Message(
        chatId: '',
        messageId: '',
        senderDid: '',
        value: '',
        isFromMe: false,
        dateCreated: DateTime.utc(2026),
        status: ChatItemStatus.received,
      ),
    );
  });

  setUp(() {
    repo = _MockChatRepository();
    stream = ChatStream();
    reactionStore = IncomingReactionStateStore();
    emitted = [];
    storedItems = [];
    eventIdMap = {};
    stream.listen(emitted.add);

    handler = ReactionHandler(
      chatRepository: repo,
      chatStream: stream,
      chatId: _chatId,
      serverEventIdToMessageId: eventIdMap,
      reactionStateStore: reactionStore,
    );

    when(() => repo.updateMesssage(any())).thenAnswer((i) async {
      return i.positionalArguments.first as ChatItem;
    });
    when(() => repo.listMessages(_chatId)).thenAnswer((_) async => storedItems);
    when(
      () => repo.getMessage(
        chatId: any(named: 'chatId'),
        messageId: any(named: 'messageId'),
      ),
    ).thenAnswer((_) async => null);
  });

  group('ReactionHandler', () {
    test('resolves target by transportId and appends reaction', () async {
      final stored = _message();
      storedItems = [stored];
      when(
        () => repo.getMessage(
          chatId: _chatId,
          messageId: any(named: 'messageId'),
        ),
      ).thenAnswer((_) async => null);

      await handler.handle(_reactionEvent(targetEventId: stored.transportId!));

      expect(
        stored.reactions,
        equals([const MessageReaction(emoji: '👍', senderDid: _bobDid)]),
      );
      verify(() => repo.updateMesssage(stored)).called(1);
      await Future<void>.delayed(Duration.zero);
      expect(emitted, hasLength(1));
    });

    test('resolves target via the live session map when present', () async {
      final stored = _message();
      storedItems = [stored];
      eventIdMap[r'$server-1'] = stored.messageId;
      when(
        () => repo.getMessage(chatId: _chatId, messageId: stored.messageId),
      ).thenAnswer((_) async => stored);

      await handler.handle(_reactionEvent(targetEventId: r'$server-1'));

      expect(
        stored.reactions,
        equals([const MessageReaction(emoji: '👍', senderDid: _bobDid)]),
      );
      verify(() => repo.updateMesssage(stored)).called(1);
      await Future<void>.delayed(Duration.zero);
      expect(emitted, hasLength(1));
    });

    test('ignores reaction when target is locally deleted', () async {
      final stored = _message(isDeletedLocally: true);
      storedItems = [stored];

      await handler.handle(_reactionEvent(targetEventId: stored.transportId!));

      expect(stored.reactions, isEmpty);
      verifyNever(() => repo.updateMesssage(any()));
      expect(emitted, isEmpty);
    });

    test('ignores reaction when target is wire-deleted', () async {
      final stored = _message(isDeleted: true);
      storedItems = [stored];

      await handler.handle(_reactionEvent(targetEventId: stored.transportId!));

      expect(stored.reactions, isEmpty);
      verifyNever(() => repo.updateMesssage(any()));
      expect(emitted, isEmpty);
    });

    test('ignores reaction when no message matches', () async {
      storedItems = [_message()];
      when(
        () => repo.getMessage(
          chatId: _chatId,
          messageId: any(named: 'messageId'),
        ),
      ).thenAnswer((_) async => null);

      await handler.handle(_reactionEvent(targetEventId: r'$unknown-event'));

      verifyNever(() => repo.updateMesssage(any()));
      expect(emitted, isEmpty);
    });

    test('registers the event for redaction even when the reaction is already '
        'applied (history replay)', () async {
      final stored = _message(
        reactions: const [MessageReaction(emoji: '👍', senderDid: _bobDid)],
      );
      storedItems = [stored];

      await handler.handle(
        _reactionEvent(targetEventId: stored.transportId!, id: r'$evt-9'),
      );

      // No duplicate mutation, but the event is still remembered so a later
      // redaction can undo the reaction.
      verifyNever(() => repo.updateMesssage(any()));
      expect(emitted, isEmpty);
      final entry = reactionStore.popByEventId(r'$evt-9');
      expect(entry, isNotNull);
      expect(entry!.emoji, '👍');
      expect(entry.senderDid, _bobDid);
    });
  });
}
