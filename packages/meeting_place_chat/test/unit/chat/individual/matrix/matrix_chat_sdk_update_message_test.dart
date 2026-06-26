import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../../_helpers/mocks.dart';

const _aliceDid = 'did:test:alice';
const _bobDid = 'did:test:bob';
const _mediatorDid = 'did:test:mediator';

IndividualMatrixChatSDK _buildSdk({
  required MockCoreSDK core,
  required MockChatRepository repo,
}) => IndividualMatrixChatSDK(
  coreSDK: core,
  did: _aliceDid,
  otherPartyDid: _bobDid,
  mediatorDid: _mediatorDid,
  chatRepository: repo,
  options: MeetingPlaceChatSDKOptions(
    chatPresenceSendInterval: const Duration(hours: 1),
  ),
);

Message _message({String messageId = 'msg-1'}) => Message(
  chatId: Chat.deriveId(did: _aliceDid, otherPartyDid: _bobDid),
  messageId: messageId,
  senderDid: _aliceDid,
  value: 'hello',
  isFromMe: true,
  dateCreated: DateTime.now().toUtc(),
  status: ChatItemStatus.sent,
);

void main() {
  late MockCoreSDK core;
  late MockChatRepository repo;
  late IndividualMatrixChatSDK sdk;

  setUp(() {
    core = MockCoreSDK();
    repo = MockChatRepository();
    sdk = _buildSdk(core: core, repo: repo);
  });

  group('updateMessage', () {
    test('persists the message via repository', () async {
      final message = _message();
      when(() => repo.updateMesssage(message)).thenAnswer((_) async => message);

      await sdk.updateMessage(message);

      verify(() => repo.updateMesssage(message)).called(1);
    });

    test('emits ChatMessageUpdatedEvent on the chat stream', () async {
      final message = _message();
      when(() => repo.updateMesssage(message)).thenAnswer((_) async => message);

      final eventFuture = sdk.chatStream.stream.first;
      await sdk.updateMessage(message);
      final emitted = await eventFuture;

      expect(emitted.event, isA<ChatMessageUpdatedEvent>());
    });

    test('includes the updated chatItem in the stream emission', () async {
      final message = _message(messageId: 'msg-42');
      when(() => repo.updateMesssage(message)).thenAnswer((_) async => message);

      final eventFuture = sdk.chatStream.stream.first;
      await sdk.updateMessage(message);
      final emitted = await eventFuture;

      expect(emitted.chatItem?.messageId, 'msg-42');
    });
  });
}
