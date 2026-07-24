import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_matrix/meeting_place_matrix.dart';
import 'package:meeting_place_matrix/src/chat/individual/individual_matrix_chat_sdk.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockCoreSDK extends Mock implements MeetingPlaceCoreSDK {}

class _MockChatRepository extends Mock implements ChatRepository {}

const _aliceDid = 'did:test:alice';
const _bobDid = 'did:test:bob';
const _mediatorDid = 'did:test:mediator';
const _callId = 'room1@1700000000000';

final _chatId = Chat.deriveId(did: _aliceDid, otherPartyDid: _bobDid);

IndividualMatrixChatSDK _buildSdk({
  required _MockCoreSDK core,
  required _MockChatRepository repo,
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

Message _callMessage({
  required String messageId,
  required bool isFromMe,
  required String callId,
}) => Message(
  chatId: _chatId,
  messageId: messageId,
  senderDid: isFromMe ? _aliceDid : _bobDid,
  value: '',
  isFromMe: isFromMe,
  dateCreated: DateTime.now().toUtc(),
  status: isFromMe ? ChatItemStatus.sent : ChatItemStatus.received,
  attachments: [
    CallMetadata.buildAttachment(
      mediaType: CallMediaType.audio,
      status: CallStatus.ended,
      id: 'att-$messageId',
      callId: callId,
    ),
  ],
);

Message _plainMessage() => Message(
  chatId: _chatId,
  messageId: 'plain-1',
  senderDid: _bobDid,
  value: 'hi',
  isFromMe: false,
  dateCreated: DateTime.now().toUtc(),
  status: ChatItemStatus.received,
);

void main() {
  late _MockCoreSDK core;
  late _MockChatRepository repo;
  late IndividualMatrixChatSDK sdk;

  setUp(() {
    core = _MockCoreSDK();
    repo = _MockChatRepository();
    sdk = _buildSdk(core: core, repo: repo);
  });

  void stubMessages(List<ChatItem> items) {
    when(() => repo.listMessages(_chatId)).thenAnswer((_) async => items);
  }

  group('MeetingPlaceMatrixChatSDK.getCallChatItemByCallId', () {
    test('returns the item whose call attachment matches callId', () async {
      final match = _callMessage(
        messageId: 'call-1',
        isFromMe: false,
        callId: _callId,
      );
      stubMessages([_plainMessage(), match]);

      final result = await sdk.getCallChatItemByCallId(_callId);

      expect(result?.messageId, 'call-1');
    });

    test('prefers the device own outgoing item over an incoming one', () async {
      final incoming = _callMessage(
        messageId: 'in-1',
        isFromMe: false,
        callId: _callId,
      );
      final outgoing = _callMessage(
        messageId: 'out-1',
        isFromMe: true,
        callId: _callId,
      );
      stubMessages([incoming, outgoing]);

      final result = await sdk.getCallChatItemByCallId(_callId);

      expect(result?.messageId, 'out-1');
    });

    test('returns null when no item carries the callId', () async {
      stubMessages([
        _plainMessage(),
        _callMessage(messageId: 'other', isFromMe: true, callId: 'room9@1'),
      ]);

      final result = await sdk.getCallChatItemByCallId(_callId);

      expect(result, isNull);
    });

    test('returns null for an empty callId without querying', () async {
      final result = await sdk.getCallChatItemByCallId('');

      expect(result, isNull);
      verifyNever(() => repo.listMessages(any()));
    });
  });
}
