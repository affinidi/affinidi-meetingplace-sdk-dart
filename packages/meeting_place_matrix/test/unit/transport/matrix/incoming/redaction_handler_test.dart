import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_matrix/src/transport/matrix/incoming/incoming_reaction_state_store.dart';
import 'package:meeting_place_matrix/src/transport/matrix/incoming/redaction_handler.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../../meeting_place_matrix.dart';

class _MockChatRepository extends Mock implements ChatRepository {}

const _chatId = 'chat-1';
const _aliceDid = 'did:test:alice';

MatrixRoomEvent _redactionEvent({
  required String redacts,
  String senderDid = _aliceDid,
  String id = r'$redaction-1',
}) => MatrixRoomEvent(
  id: id,
  type: 'm.room.redaction',
  senderDid: senderDid,
  roomId: '!room:server',
  content: {'redacts': redacts},
  timestamp: DateTime.utc(2026, 1, 1, 12),
);

Message _message({
  String messageId = 'local-1',
  String? transportId = r'$server-1',
  bool isDeleted = false,
  List<MessageReaction> reactions = const [],
}) => Message(
  chatId: _chatId,
  messageId: messageId,
  senderDid: _aliceDid,
  value: 'hello',
  isFromMe: false,
  dateCreated: DateTime.utc(2026, 1, 1, 11),
  status: ChatItemStatus.received,
  transportId: transportId,
  isDeleted: isDeleted,
  reactions: reactions,
);

void main() {
  late _MockChatRepository repo;
  late ChatStream stream;
  late IncomingReactionStateStore reactionStore;
  late RedactionHandler handler;
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

    handler = RedactionHandler(
      chatRepository: repo,
      chatStream: stream,
      chatId: _chatId,
      reactionStateStore: reactionStore,
    );

    when(() => repo.updateMesssage(any())).thenAnswer((i) async {
      return i.positionalArguments.first as ChatItem;
    });
  });

  group('RedactionHandler', () {
    test('marks message as deleted when redaction targets a message', () async {
      final stored = _message();
      when(() => repo.listMessages(_chatId)).thenAnswer((_) async => [stored]);

      await handler.handle(_redactionEvent(redacts: stored.transportId!));

      expect(stored.isDeleted, isTrue);
      expect(stored.value, isEmpty);
      expect(stored.attachments, isEmpty);
      verify(() => repo.updateMesssage(stored)).called(1);
      await Future<void>.delayed(Duration.zero);
      expect(emitted.length, 1);
      expect(emitted.single.chatItem, same(stored));
    });

    test('removes reaction when redaction targets a reaction', () async {
      final stored = _message(
        reactions: const [MessageReaction(emoji: '👍', senderDid: _aliceDid)],
      );
      reactionStore.register(
        eventId: r'$reaction-evt',
        messageId: stored.messageId,
        reaction: '👍',
        senderDid: _aliceDid,
      );
      when(
        () => repo.getMessage(chatId: _chatId, messageId: stored.messageId),
      ).thenAnswer((_) async => stored);

      await handler.handle(_redactionEvent(redacts: r'$reaction-evt'));

      expect(stored.reactions, isEmpty);
      expect(stored.isDeleted, isFalse);
      expect(stored.value, 'hello');
      verify(() => repo.updateMesssage(stored)).called(1);
      verifyNever(() => repo.listMessages(any()));
    });

    test('is a no-op when redaction target is unknown', () async {
      when(
        () => repo.listMessages(_chatId),
      ).thenAnswer((_) async => <ChatItem>[]);

      await handler.handle(_redactionEvent(redacts: r'$ghost'));

      verifyNever(() => repo.updateMesssage(any()));
      expect(emitted, isEmpty);
    });

    test('is idempotent when target message is already deleted', () async {
      final stored = _message(isDeleted: true);
      when(() => repo.listMessages(_chatId)).thenAnswer((_) async => [stored]);

      await handler.handle(_redactionEvent(redacts: stored.transportId!));

      verifyNever(() => repo.updateMesssage(any()));
      expect(emitted, isEmpty);
    });

    test('ignores events without a redacts target', () async {
      final bad = MatrixRoomEvent(
        id: r'$x',
        type: 'm.room.redaction',
        senderDid: _aliceDid,
        roomId: '!room:server',
        content: const <String, dynamic>{},
        timestamp: DateTime.utc(2026, 1, 1, 12),
      );

      await handler.handle(bad);

      verifyNever(() => repo.listMessages(any()));
      verifyNever(() => repo.updateMesssage(any()));
    });
  });
}
