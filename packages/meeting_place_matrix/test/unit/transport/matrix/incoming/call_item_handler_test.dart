import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_matrix/meeting_place_matrix.dart';
import 'package:meeting_place_matrix/src/transport/matrix/incoming/call_item_handler.dart';
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
const _senderDid = 'did:test:alice';
const _eventId = r'$call-item-event';

MatrixRoomEvent _callItemEvent({
  String id = _eventId,
  String? senderDid = _senderDid,
  String? userId,
  Map<String, dynamic>? metadata,
}) => MatrixRoomEvent(
  id: id,
  type: MpxCallEventType.callItem,
  senderDid: senderDid,
  userId: userId ?? (senderDid == null ? '@unknown:server' : null),
  roomId: '!room:server',
  content: {if (metadata != null) MatrixEventField.callMetadata: metadata},
  timestamp: DateTime.utc(2026, 1, 1, 12),
);

void main() {
  late _MockChatRepository repo;
  late ChatStream stream;
  late CallItemHandler handler;
  late Map<String, String> idMap;
  late Map<String, ChatItem> store;
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
    store = {};
    emitted = [];
    stream.listen(emitted.add);

    handler = CallItemHandler(
      chatRepository: repo,
      chatStream: stream,
      chatId: _chatId,
      serverEventIdToMessageId: idMap,
      logger: _SilentLogger(),
    );

    when(() => repo.createMessage(any())).thenAnswer((inv) async {
      final item = inv.positionalArguments.first as ChatItem;
      store[item.messageId] = item;
      return item;
    });
  });

  group('CallItemHandler', () {
    test(
      'persists message with metadata attachment and pushes to stream',
      () async {
        final metadata = {'call_duration': 42, 'media_type': 'video'};

        await handler.handle(_callItemEvent(metadata: metadata));
        await Future<void>.delayed(Duration.zero);

        verify(() => repo.createMessage(any())).called(1);
        expect(store, hasLength(1));

        final message = store.values.single as Message;
        expect(message.chatId, _chatId);
        expect(message.senderDid, _senderDid);
        expect(message.isFromMe, isFalse);
        expect(message.status, ChatItemStatus.received);
        expect(message.attachments, hasLength(1));

        final attachment = message.attachments.single;
        expect(attachment.metadata, metadata);
        expect(attachment.transportId, _eventId);

        expect(idMap[_eventId], message.messageId);
        expect(emitted, hasLength(1));
      },
    );

    test('skips event when senderDid is null', () async {
      await handler.handle(
        _callItemEvent(senderDid: null, metadata: {'k': 'v'}),
      );
      await Future<void>.delayed(Duration.zero);

      verifyNever(() => repo.createMessage(any()));
      expect(store, isEmpty);
      expect(emitted, isEmpty);
    });

    test('skips event when callMetadata field is absent', () async {
      await handler.handle(_callItemEvent());
      await Future<void>.delayed(Duration.zero);

      verifyNever(() => repo.createMessage(any()));
      expect(store, isEmpty);
      expect(emitted, isEmpty);
    });

    test('skips event when callMetadata is not a Map', () async {
      await handler.handle(
        MatrixRoomEvent(
          id: _eventId,
          type: MpxCallEventType.callItem,
          senderDid: _senderDid,
          roomId: '!room:server',
          content: {MatrixEventField.callMetadata: 'not-a-map'},
          timestamp: DateTime.utc(2026, 1, 1, 12),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      verifyNever(() => repo.createMessage(any()));
      expect(store, isEmpty);
      expect(emitted, isEmpty);
    });

    test('each event produces a distinct message', () async {
      final metadata = {'k': 'v'};
      await handler.handle(_callItemEvent(id: r'$evt-1', metadata: metadata));
      await handler.handle(_callItemEvent(id: r'$evt-2', metadata: metadata));
      await Future<void>.delayed(Duration.zero);

      verify(() => repo.createMessage(any())).called(2);
      expect(store, hasLength(2));
      expect(emitted, hasLength(2));
    });
  });
}
