import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_matrix/meeting_place_matrix.dart';
import 'package:meeting_place_matrix/src/transport/matrix/incoming/message_edit_handler.dart';
import 'package:meeting_place_matrix/src/transport/matrix/incoming/text_message_handler.dart';
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

MatrixRoomEvent _imageEvent({
  required String id,
  required String filename,
  required String attachmentId,
  String? correlationId,
  String? caption,
  String senderDid = _aliceDid,
  DateTime? timestamp,
}) => MatrixRoomEvent(
  id: id,
  type: 'm.room.message',
  senderDid: senderDid,
  roomId: '!room:server',
  content: {
    'msgtype': 'm.image',
    'body': caption ?? filename,
    'filename': filename,
    'info': {'mimetype': 'image/jpeg', 'size': 1234},
    MatrixEventField.attachmentId: attachmentId,
    if (correlationId != null) MatrixEventField.correlationId: correlationId,
  },
  timestamp: timestamp ?? DateTime.utc(2026, 1, 1, 12),
);

void main() {
  late _MockChatRepository repo;
  late ChatStream stream;
  late TextMessageHandler handler;
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

    handler = TextMessageHandler(
      chatRepository: repo,
      chatStream: stream,
      chatId: _chatId,
      serverEventIdToMessageId: idMap,
      logger: _SilentLogger(),
      editHandler: MessageEditHandler(
        chatRepository: repo,
        chatStream: stream,
        chatId: _chatId,
        serverEventIdToMessageId: idMap,
        logger: _SilentLogger(),
      ),
    );

    when(
      () => repo.getMessage(
        chatId: any(named: 'chatId'),
        messageId: any(named: 'messageId'),
      ),
    ).thenAnswer((inv) async {
      final messageId = inv.namedArguments[#messageId] as String;
      return store[messageId];
    });

    when(() => repo.createMessage(any())).thenAnswer((inv) async {
      final item = inv.positionalArguments.first as ChatItem;
      store[item.messageId] = item;
      return item;
    });

    when(() => repo.updateMesssage(any())).thenAnswer((inv) async {
      final item = inv.positionalArguments.first as ChatItem;
      store[item.messageId] = item;
      return item;
    });
  });

  group('TextMessageHandler coalescing', () {
    test(
      'absent correlationId: legacy one-event-one-Message, keyed on event id',
      () async {
        await handler.handle(
          _imageEvent(
            id: r'$evt-1',
            attachmentId: 'attachment-1',
            filename: 'a.jpg',
          ),
        );

        verify(() => repo.createMessage(any())).called(1);
        expect(store.keys, contains(r'$evt-1'));
        final stored = store[r'$evt-1']! as Message;
        expect(stored.messageId, r'$evt-1');
        expect(stored.transportId, r'$evt-1');
        expect(stored.attachments, hasLength(1));
        expect(stored.attachments.single.transportId, r'$evt-1');
        expect(idMap, isEmpty);
      },
    );

    test(
      'correlationId miss: creates one Message keyed on the correlation id',
      () async {
        await handler.handle(
          _imageEvent(
            id: r'$evt-1',
            attachmentId: 'attachment-1',
            filename: 'a.jpg',
            correlationId: 'corr-uuid',
            caption: 'My caption',
          ),
        );

        verify(() => repo.createMessage(any())).called(1);
        expect(store.keys, ['corr-uuid']);
        final stored = store['corr-uuid']! as Message;
        expect(stored.messageId, 'corr-uuid');
        expect(stored.attachments, hasLength(1));
        expect(stored.attachments.single.id, 'attachment-1');
        expect(stored.attachments.single.transportId, r'$evt-1');
        expect(idMap[r'$evt-1'], 'corr-uuid');
      },
    );

    test(
      'correlationId hit: appends attachments to the existing logical Message',
      () async {
        await handler.handle(
          _imageEvent(
            id: r'$evt-1',
            attachmentId: 'attachment-1',
            filename: 'a.jpg',
            correlationId: 'corr-uuid',
          ),
        );
        await handler.handle(
          _imageEvent(
            id: r'$evt-2',
            attachmentId: 'attachment-2',
            filename: 'b.jpg',
            correlationId: 'corr-uuid',
          ),
        );

        verify(() => repo.createMessage(any())).called(1);
        verify(() => repo.updateMesssage(any())).called(1);
        expect(store.keys, ['corr-uuid']);

        final stored = store['corr-uuid']! as Message;
        expect(stored.attachments, hasLength(2));
        expect(stored.attachments[0].transportId, r'$evt-1');
        expect(stored.attachments[0].filename, 'a.jpg');
        expect(stored.attachments[1].transportId, r'$evt-2');
        expect(stored.attachments[1].filename, 'b.jpg');
        expect(idMap[r'$evt-1'], 'corr-uuid');
        expect(idMap[r'$evt-2'], 'corr-uuid');
      },
    );

    test(
      'reprocessing the same correlated event does not duplicate attachments',
      () async {
        final event = _imageEvent(
          id: r'$evt-1',
          attachmentId: 'attachment-1',
          filename: 'a.jpg',
          correlationId: 'corr-uuid',
        );

        await handler.handle(event);
        await handler.handle(event);

        verify(() => repo.createMessage(any())).called(1);
        verify(() => repo.updateMesssage(any())).called(1);

        final stored = store['corr-uuid']! as Message;
        expect(stored.attachments, hasLength(1));
        expect(stored.attachments.single.transportId, r'$evt-1');
      },
    );

    test('out-of-order arrival: second event arrives first, first later '
        'is appended into the same logical Message', () async {
      // The "second" matrix event arrives first.
      await handler.handle(
        _imageEvent(
          id: r'$evt-2',
          attachmentId: 'attachment-2',
          filename: 'b.jpg',
          correlationId: 'corr-uuid',
        ),
      );
      // Then the originally-first event lands.
      await handler.handle(
        _imageEvent(
          id: r'$evt-1',
          attachmentId: 'attachment-1',
          filename: 'a.jpg',
          correlationId: 'corr-uuid',
          caption: 'My caption',
        ),
      );

      verify(() => repo.createMessage(any())).called(1);
      verify(() => repo.updateMesssage(any())).called(1);
      expect(store.keys, ['corr-uuid']);

      final stored = store['corr-uuid']! as Message;
      expect(stored.attachments, hasLength(2));
      // Arrival order is preserved (b first, then a). The Message itself
      // is created from whichever event arrived first.
      expect(stored.attachments[0].transportId, r'$evt-2');
      expect(stored.attachments[1].transportId, r'$evt-1');
      expect(idMap[r'$evt-1'], 'corr-uuid');
      expect(idMap[r'$evt-2'], 'corr-uuid');
    });

    test(
      'm.replace edit events bypass coalescing and reach edit handler',
      () async {
        // Seed a Message for the edit to target.
        final original = Message(
          chatId: _chatId,
          messageId: r'$orig',
          senderDid: _aliceDid,
          value: 'original',
          isFromMe: false,
          dateCreated: DateTime.utc(2026, 1, 1, 11),
          status: ChatItemStatus.received,
        );
        store[r'$orig'] = original;

        final edit = MatrixRoomEvent(
          id: r'$edit',
          type: 'm.room.message',
          senderDid: _aliceDid,
          roomId: '!room:server',
          content: {
            'msgtype': 'm.text',
            'body': '* edited',
            'm.new_content': {'msgtype': 'm.text', 'body': 'edited'},
            'm.relates_to': {'rel_type': 'm.replace', 'event_id': r'$orig'},
            // A correlation id on an edit must NOT cause a new Message to be
            // created — the edit-relation early-return takes precedence.
            MatrixEventField.correlationId: 'corr-uuid',
          },
          timestamp: DateTime.utc(2026, 1, 1, 13),
        );

        await handler.handle(edit);

        verifyNever(() => repo.createMessage(any()));
        expect(original.value, 'edited');
      },
    );
  });
}
