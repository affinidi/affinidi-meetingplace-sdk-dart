import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_chat/src/transport/matrix/outgoing/redaction_room_event.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockCoreSDK extends Mock implements MeetingPlaceCoreSDK {}

class _MockChatRepository extends Mock implements ChatRepository {}

const _aliceDid = 'did:test:alice';
const _bobDid = 'did:test:bob';
const _mediatorDid = 'did:test:mediator';

IndividualMatrixChatSDK _buildSdk({
  required _MockCoreSDK core,
  required _MockChatRepository repo,
  Duration window = const Duration(minutes: 2),
}) => IndividualMatrixChatSDK(
  coreSDK: core,
  did: _aliceDid,
  otherPartyDid: _bobDid,
  mediatorDid: _mediatorDid,
  chatRepository: repo,
  options: MeetingPlaceChatSDKOptions(
    chatPresenceSendInterval: const Duration(hours: 1),
    deleteMessageWindow: window,
  ),
);

Message _ownMessage({
  String messageId = 'local-1',
  String? transportId = r'$server-1',
  DateTime? dateCreated,
  bool isDeleted = false,
}) => Message(
  chatId: Chat.deriveId(did: _aliceDid, otherPartyDid: _bobDid),
  messageId: messageId,
  senderDid: _aliceDid,
  value: 'hello',
  isFromMe: true,
  dateCreated: dateCreated ?? DateTime.now().toUtc(),
  status: ChatItemStatus.sent,
  transportId: transportId,
  isDeleted: isDeleted,
);

Message _otherMessage() => Message(
  chatId: Chat.deriveId(did: _aliceDid, otherPartyDid: _bobDid),
  messageId: 'local-2',
  senderDid: _bobDid,
  value: 'hi alice',
  isFromMe: false,
  dateCreated: DateTime.now().toUtc(),
  status: ChatItemStatus.received,
  transportId: r'$server-2',
);

void main() {
  late _MockCoreSDK core;
  late _MockChatRepository repo;
  late IndividualMatrixChatSDK sdk;

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
    registerFallbackValue(RedactionRoomEvent(senderDid: '', targetEventId: ''));
  });

  setUp(() {
    core = _MockCoreSDK();
    repo = _MockChatRepository();
    sdk = _buildSdk(core: core, repo: repo);

    when(() => repo.updateMesssage(any())).thenAnswer((i) async {
      return i.positionalArguments.first as ChatItem;
    });
    when(() => core.sendMessage(any())).thenAnswer((_) async => r'$ok');
  });

  group('MatrixChatSDK.deleteMessage (localOnly: true)', () {
    test('flips isDeletedLocally without sending anything', () async {
      final msg = _ownMessage();

      await sdk.deleteMessage(msg, localOnly: true);

      expect(msg.isDeletedLocally, isTrue);
      expect(msg.isDeleted, isFalse);
      expect(msg.value, isEmpty);
      verify(() => repo.updateMesssage(msg)).called(1);
      verifyNever(() => core.sendMessage(any()));
    });

    test('is idempotent', () async {
      final msg = _ownMessage();
      await sdk.deleteMessage(msg, localOnly: true);
      clearInteractions(repo);

      await sdk.deleteMessage(msg, localOnly: true);

      verifyNever(() => repo.updateMesssage(any()));
    });

    test('works on undelivered messages (no transportId)', () async {
      final msg = _ownMessage(transportId: null);

      await sdk.deleteMessage(msg, localOnly: true);

      expect(msg.isDeletedLocally, isTrue);
    });

    test('throws when message is not authored by me', () async {
      final msg = _otherMessage();

      expect(
        () => sdk.deleteMessage(msg, localOnly: true),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('original sender'),
          ),
        ),
      );
      verifyNever(() => repo.updateMesssage(any()));
    });
  });

  group('MatrixChatSDK.deleteMessage (wire delete)', () {
    test(
      'sends a redaction and flips isDeleted on own fresh message',
      () async {
        final msg = _ownMessage();

        await sdk.deleteMessage(msg);

        expect(msg.isDeleted, isTrue);
        expect(msg.value, isEmpty);
        expect(msg.attachments, isEmpty);
        expect(msg.reactions, isEmpty);
        expect(msg.editedAt, isNull);
        final captured = verify(() => core.sendMessage(captureAny())).captured;
        expect(captured.single, isA<RedactionRoomEvent>());
        final redaction = captured.single as RedactionRoomEvent;
        expect(redaction.content['redacts'], r'$server-1');
      },
    );

    test('throws when message is not authored by me', () async {
      final msg = _otherMessage();

      expect(
        () => sdk.deleteMessage(msg),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('original sender'),
          ),
        ),
      );
      verifyNever(() => core.sendMessage(any()));
    });

    test('throws when message has no transportId', () async {
      final msg = _ownMessage(transportId: null);

      expect(
        () => sdk.deleteMessage(msg),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('not yet been delivered'),
          ),
        ),
      );
    });

    test('throws when message is older than the window', () async {
      final msg = _ownMessage(
        dateCreated: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
      );

      expect(
        () => sdk.deleteMessage(msg),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('expired'),
          ),
        ),
      );
      verifyNever(() => core.sendMessage(any()));
    });

    test('throws when window is Duration.zero', () async {
      sdk = _buildSdk(core: core, repo: repo, window: Duration.zero);
      final msg = _ownMessage();

      expect(() => sdk.deleteMessage(msg), throwsA(isA<StateError>()));
      verifyNever(() => core.sendMessage(any()));
    });

    test('rolls back isDeleted and content when wire send fails', () async {
      final msg = _ownMessage();
      final originalValue = msg.value;
      when(() => core.sendMessage(any())).thenThrow(Exception('network down'));

      await expectLater(() => sdk.deleteMessage(msg), throwsException);

      expect(msg.isDeleted, isFalse);
      expect(msg.value, originalValue);
      // Two repository updates: optimistic flip true, then rollback false.
      verify(() => repo.updateMesssage(msg)).called(2);
    });

    test('is a no-op when already deleted', () async {
      final msg = _ownMessage(isDeleted: true);

      await sdk.deleteMessage(msg);

      verifyNever(() => core.sendMessage(any()));
      verifyNever(() => repo.updateMesssage(any()));
    });
  });
}
