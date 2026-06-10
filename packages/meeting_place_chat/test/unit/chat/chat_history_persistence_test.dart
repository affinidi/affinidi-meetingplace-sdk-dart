import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../utils/repository/chat_repository_impl.dart';
import '../../utils/storage/in_memory_storage.dart';

class _MockCoreSDK extends Mock implements MeetingPlaceCoreSDK {}

const _aliceDid = 'did:test:alice';
const _bobDid = 'did:test:bob';
const _charlieDid = 'did:test:charlie';
const _mediatorDid = 'did:test:mediator';

IndividualDidcommChatSDK _buildSdk({
  required MeetingPlaceCoreSDK core,
  required ChatRepository repo,
  String otherPartyDid = _bobDid,
}) => IndividualDidcommChatSDK(
  coreSDK: core,
  did: _aliceDid,
  otherPartyDid: otherPartyDid,
  mediatorDid: _mediatorDid,
  chatRepository: repo,
  options: MeetingPlaceChatSDKOptions(
    chatPresenceSendInterval: const Duration(hours: 1),
  ),
);

void main() {
  late _MockCoreSDK core;

  setUp(() {
    core = _MockCoreSDK();
  });

  group('chat history persistence', () {
    test(
      'messages persist across SDK re-instantiation with shared storage',
      () async {
        final storage = InMemoryStorage();
        final repo = ChatRepositoryImpl(storage: storage);

        final chatId = Chat.deriveId(did: _aliceDid, otherPartyDid: _bobDid);
        await repo.createMessage(
          Message(
            chatId: chatId,
            messageId: 'msg-1',
            senderDid: _aliceDid,
            value: 'Hello World!',
            isFromMe: true,
            dateCreated: DateTime.utc(2026),
            status: ChatItemStatus.sent,
          ),
        );

        final sdk = _buildSdk(core: core, repo: repo);
        final messages = await sdk.messages;
        expect(messages.length, equals(1));
        expect((messages.first as Message).value, 'Hello World!');
      },
    );

    test('messages are scoped to chat ID', () async {
      final storage = InMemoryStorage();
      final repo = ChatRepositoryImpl(storage: storage);

      final bobChatId = Chat.deriveId(did: _aliceDid, otherPartyDid: _bobDid);
      final charlieChatId = Chat.deriveId(
        did: _aliceDid,
        otherPartyDid: _charlieDid,
      );

      await repo.createMessage(
        Message(
          chatId: bobChatId,
          messageId: 'msg-bob',
          senderDid: _aliceDid,
          value: 'Hello Bob!',
          isFromMe: true,
          dateCreated: DateTime.utc(2026),
          status: ChatItemStatus.sent,
        ),
      );

      await repo.createMessage(
        Message(
          chatId: charlieChatId,
          messageId: 'msg-charlie',
          senderDid: _aliceDid,
          value: 'Hello Charlie!',
          isFromMe: true,
          dateCreated: DateTime.utc(2026),
          status: ChatItemStatus.sent,
        ),
      );

      final bobSdk = _buildSdk(core: core, repo: repo, otherPartyDid: _bobDid);
      final charlieSdk = _buildSdk(
        core: core,
        repo: repo,
        otherPartyDid: _charlieDid,
      );

      final bobMessages = await bobSdk.messages;
      expect(bobMessages.length, equals(1));
      expect((bobMessages.first as Message).value, 'Hello Bob!');

      final charlieMessages = await charlieSdk.messages;
      expect(charlieMessages.length, equals(1));
      expect((charlieMessages.first as Message).value, 'Hello Charlie!');
    });
  });
}
