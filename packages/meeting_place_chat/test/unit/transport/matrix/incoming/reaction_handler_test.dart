import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_chat/src/transport/matrix/incoming/incoming_reaction_state_store.dart';
import 'package:meeting_place_chat/src/transport/matrix/incoming/reaction_handler.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
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
);

void main() {
  late _MockChatRepository repo;
  late ChatStream stream;
  late IncomingReactionStateStore reactionStore;
  late ReactionHandler handler;
  late List<StreamData> emitted;

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
    stream.listen(emitted.add);

    handler = ReactionHandler(
      chatRepository: repo,
      chatStream: stream,
      chatId: _chatId,
      serverEventIdToMessageId: {},
      reactionStateStore: reactionStore,
    );

    when(() => repo.updateMesssage(any())).thenAnswer((i) async {
      return i.positionalArguments.first as ChatItem;
    });
  });

  group('ReactionHandler', () {
    test('appends reaction on a normal message', () async {
      final stored = _message();
      when(
        () => repo.getMessage(chatId: _chatId, messageId: stored.messageId),
      ).thenAnswer((_) async => stored);

      await handler.handle(_reactionEvent(targetEventId: stored.messageId));

      expect(stored.reactions, equals(['👍']));
      verify(() => repo.updateMesssage(stored)).called(1);
      await Future<void>.delayed(Duration.zero);
      expect(emitted, hasLength(1));
    });

    test('ignores reaction when target is locally deleted', () async {
      final stored = _message(isDeletedLocally: true);
      when(
        () => repo.getMessage(chatId: _chatId, messageId: stored.messageId),
      ).thenAnswer((_) async => stored);

      await handler.handle(_reactionEvent(targetEventId: stored.messageId));

      expect(stored.reactions, isEmpty);
      verifyNever(() => repo.updateMesssage(any()));
      expect(emitted, isEmpty);
    });

    test('ignores reaction when target is wire-deleted', () async {
      final stored = _message(isDeleted: true);
      when(
        () => repo.getMessage(chatId: _chatId, messageId: stored.messageId),
      ).thenAnswer((_) async => stored);

      await handler.handle(_reactionEvent(targetEventId: stored.messageId));

      expect(stored.reactions, isEmpty);
      verifyNever(() => repo.updateMesssage(any()));
      expect(emitted, isEmpty);
    });
  });
}
