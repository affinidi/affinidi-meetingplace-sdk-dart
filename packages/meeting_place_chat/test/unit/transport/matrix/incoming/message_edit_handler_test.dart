import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_chat/src/transport/matrix/incoming/message_edit_handler.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockChatRepository extends Mock implements ChatRepository {}

class _SilentLogger implements MeetingPlaceChatSDKLogger {
  @override
  void debug(String message, {String name = ''}) {}
  @override
  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String name = '',
  }) {}
  @override
  void info(String message, {String name = ''}) {}
  @override
  void warning(String message, {String name = ''}) {}
}

const _chatId = 'chat-1';
const _aliceDid = 'did:test:alice';
const _bobDid = 'did:test:bob';

MatrixRoomEvent _editEvent({
  required String targetEventId,
  required String newBody,
  String senderDid = _aliceDid,
  DateTime? timestamp,
  String id = r'$edit-1',
}) => MatrixRoomEvent(
  id: id,
  type: 'm.room.message',
  senderDid: senderDid,
  roomId: '!room:server',
  content: {
    'msgtype': 'm.text',
    'body': '* $newBody',
    'm.new_content': {'msgtype': 'm.text', 'body': newBody},
    'm.relates_to': {'rel_type': 'm.replace', 'event_id': targetEventId},
  },
  timestamp: timestamp ?? DateTime.utc(2026, 1, 1, 12),
);

Message _message({
  String messageId = r'$orig-1',
  String value = 'original',
  String senderDid = _aliceDid,
  DateTime? editedAt,
}) => Message(
  chatId: _chatId,
  messageId: messageId,
  senderDid: senderDid,
  value: value,
  isFromMe: false,
  dateCreated: DateTime.utc(2026, 1, 1, 11),
  status: ChatItemStatus.received,
  editedAt: editedAt,
);

void main() {
  late _MockChatRepository repo;
  late ChatStream stream;
  late MessageEditHandler handler;
  late Map<String, String> idMap;
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
    idMap = {};
    emitted = [];
    stream.listen(emitted.add);

    handler = MessageEditHandler(
      chatRepository: repo,
      chatStream: stream,
      chatId: _chatId,
      serverEventIdToMessageId: idMap,
      logger: _SilentLogger(),
    );

    when(() => repo.updateMesssage(any())).thenAnswer((i) async {
      return i.positionalArguments.first as ChatItem;
    });
  });

  group('MessageEditHandler', () {
    test('mutates target value + editedAt and pushes to the stream', () async {
      final stored = _message();
      when(
        () => repo.getMessage(chatId: _chatId, messageId: stored.messageId),
      ).thenAnswer((_) async => stored);

      final ts = DateTime.utc(2026, 1, 1, 13);
      await handler.handle(
        _editEvent(
          targetEventId: stored.messageId,
          newBody: 'edited!',
          timestamp: ts,
        ),
      );

      expect(stored.value, 'edited!');
      expect(stored.editedAt, ts);
      verify(() => repo.updateMesssage(stored)).called(1);
      await Future<void>.delayed(Duration.zero);
      expect(emitted.length, 1);
      expect(emitted.single.chatItem, same(stored));
    });

    test('resolves target via serverEventIdToMessageId indirection', () async {
      final stored = _message(messageId: 'local-uuid');
      idMap[r'$server-id'] = 'local-uuid';
      when(
        () => repo.getMessage(chatId: _chatId, messageId: 'local-uuid'),
      ).thenAnswer((_) async => stored);

      await handler.handle(
        _editEvent(targetEventId: r'$server-id', newBody: 'edited!'),
      );

      expect(stored.value, 'edited!');
    });

    test('drops edits from a non-author sender', () async {
      final stored = _message(senderDid: _aliceDid);
      when(
        () => repo.getMessage(chatId: _chatId, messageId: stored.messageId),
      ).thenAnswer((_) async => stored);

      await handler.handle(
        _editEvent(
          targetEventId: stored.messageId,
          newBody: 'hijack',
          senderDid: _bobDid,
        ),
      );

      expect(stored.value, 'original');
      verifyNever(() => repo.updateMesssage(any()));
    });

    test('drops edits whose target is unknown', () async {
      when(
        () => repo.getMessage(
          chatId: any(named: 'chatId'),
          messageId: any(named: 'messageId'),
        ),
      ).thenAnswer((_) async => null);

      await handler.handle(
        _editEvent(targetEventId: r'$missing', newBody: 'x'),
      );

      verifyNever(() => repo.updateMesssage(any()));
      expect(emitted, isEmpty);
    });

    test('drops stale edits not newer than the existing editedAt', () async {
      final priorEdit = DateTime.utc(2026, 1, 1, 14);
      final stored = _message(value: 'v2', editedAt: priorEdit);
      when(
        () => repo.getMessage(chatId: _chatId, messageId: stored.messageId),
      ).thenAnswer((_) async => stored);

      await handler.handle(
        _editEvent(
          targetEventId: stored.messageId,
          newBody: 'older',
          timestamp: DateTime.utc(2026, 1, 1, 13),
        ),
      );

      expect(stored.value, 'v2');
      expect(stored.editedAt, priorEdit);
      verifyNever(() => repo.updateMesssage(any()));
    });

    test('ignores events lacking m.new_content.body', () async {
      final stored = _message();
      when(
        () => repo.getMessage(chatId: _chatId, messageId: stored.messageId),
      ).thenAnswer((_) async => stored);

      final bad = MatrixRoomEvent(
        id: r'$e',
        type: 'm.room.message',
        senderDid: _aliceDid,
        roomId: '!room:server',
        content: {
          'msgtype': 'm.text',
          'body': '* x',
          'm.relates_to': {
            'rel_type': 'm.replace',
            'event_id': stored.messageId,
          },
        },
        timestamp: DateTime.utc(2026, 1, 1, 13),
      );

      await handler.handle(bad);

      verifyNever(() => repo.updateMesssage(any()));
    });
  });
}
