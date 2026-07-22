import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_matrix/src/transport/matrix/incoming/profile_request_handler.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../../meeting_place_matrix.dart';

class _MockChatRepository extends Mock implements ChatRepository {}

class _FakeCoreSDK extends Fake implements MeetingPlaceCoreSDK {
  @override
  Future<Channel?> getChannelByOtherPartyPermanentDid(String did) async => null;
}

const _chatId = 'chat-1';
const _otherPartyDid = 'did:test:alice';

MatrixRoomEvent _profileRequestEvent({
  required String id,
  required String profileHash,
}) => MatrixRoomEvent(
  id: id,
  type: 'profile_request',
  senderDid: _otherPartyDid,
  roomId: '!room:server',
  content: {'profile_hash': profileHash},
  timestamp: DateTime.utc(2026, 1, 1, 12),
);

void main() {
  late _MockChatRepository repo;
  late ChatStream stream;
  late ProfileRequestHandler handler;
  late Map<String, ChatItem> store;
  late List<StreamData> emitted;

  setUpAll(() {
    registerFallbackValue(
      ConciergeMessage(
        chatId: '',
        messageId: '',
        senderDid: '',
        isFromMe: false,
        dateCreated: DateTime.utc(2026),
        status: ChatItemStatus.userInput,
        conciergeType: ConciergeMessageType.permissionToUpdateProfile,
        data: const {},
      ),
    );
  });

  setUp(() {
    repo = _MockChatRepository();
    stream = ChatStream();
    store = {};
    emitted = [];
    stream.listen(emitted.add);

    handler = ProfileRequestHandler(
      coreSDK: _FakeCoreSDK(),
      chatRepository: repo,
      chatStream: stream,
      chatId: _chatId,
      otherPartyDid: _otherPartyDid,
    );

    when(
      () => repo.listMessages(_chatId),
    ).thenAnswer((_) async => store.values.toList());
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

  group('ProfileRequestHandler', () {
    test('creates a concierge message for a new profile request', () async {
      await handler.handle(
        _profileRequestEvent(id: r'$evt-1', profileHash: 'hash-1'),
      );
      await Future<void>.delayed(Duration.zero);

      verify(() => repo.createMessage(any())).called(1);
      expect(store, hasLength(1));

      final concierge = store.values.single as ConciergeMessage;
      expect(concierge.chatId, _chatId);
      expect(concierge.isFromMe, isFalse);
      expect(concierge.status, ChatItemStatus.userInput);
      expect(
        concierge.conciergeType,
        ConciergeMessageType.permissionToUpdateProfile,
      );
      expect(concierge.data['profileHash'], 'hash-1');
      expect(concierge.data['replyTo'], _otherPartyDid);
      expect(emitted, hasLength(1));
    });

    test(
      'creates a distinct concierge for each profile request event',
      () async {
        await handler.handle(
          _profileRequestEvent(id: r'$evt-1', profileHash: 'hash-1'),
        );
        await handler.handle(
          _profileRequestEvent(id: r'$evt-2', profileHash: 'hash-2'),
        );
        await Future<void>.delayed(Duration.zero);

        verify(() => repo.createMessage(any())).called(2);
        expect(store, hasLength(2));
        expect(emitted, hasLength(2));
      },
    );

    test('ignores events without a profile hash', () async {
      await handler.handle(
        MatrixRoomEvent(
          id: r'$evt-1',
          type: 'profile_request',
          senderDid: _otherPartyDid,
          roomId: '!room:server',
          content: const {},
          timestamp: DateTime.utc(2026, 1, 1, 12),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      verifyNever(() => repo.createMessage(any()));
      expect(store, isEmpty);
      expect(emitted, isEmpty);
    });
  });
}
