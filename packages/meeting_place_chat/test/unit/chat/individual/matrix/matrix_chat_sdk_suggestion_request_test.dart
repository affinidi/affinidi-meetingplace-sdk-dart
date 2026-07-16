import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockCoreSDK extends Mock implements MeetingPlaceCoreSDK {}

class _MockChatRepository extends Mock implements ChatRepository {}

const _aliceDid = 'did:test:alice';
const _bobDid = 'did:test:bob';
const _agentDid = 'did:test:agent';
const _mediatorDid = 'did:test:mediator';

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

void main() {
  late _MockCoreSDK core;
  late _MockChatRepository repo;
  late MeetingPlaceChatSDK sdk;

  setUpAll(() {
    registerFallbackValue(
      DidCommOutgoingMessage(
        senderDid: '',
        recipientDid: '',
        mediatorDid: '',
        payload: PlainTextMessage(
          id: 'fallback',
          type: Uri.parse('https://example.com'),
          body: {},
        ),
      ),
    );
  });

  setUp(() {
    core = _MockCoreSDK();
    repo = _MockChatRepository();
    sdk = _buildSdk(core: core, repo: repo);
    when(
      () => core.options,
    ).thenReturn(const MeetingPlaceCoreSDKOptions(agentDid: _agentDid));
    when(() => core.sendMessage(any())).thenAnswer((_) async => r'$ok');
  });

  test(
    'sendSuggestionRequest emits DIDComm suggestion request payload',
    () async {
      await sdk.sendSuggestionRequest(
        messageId: 'msg-42',
        text: 'Suggest a response for this message',
      );

      final captured =
          verify(() => core.sendMessage(captureAny())).captured.single
              as DidCommOutgoingMessage;
      expect(captured.senderDid, _aliceDid);
      expect(captured.recipientDid, _agentDid);
      expect(captured.mediatorDid, _mediatorDid);
      expect(
        captured.payload.type.toString(),
        ChatProtocol.suggestionRequest.value,
      );
      expect(captured.payload.to, [_agentDid]);
      expect(captured.payload.body?['message_id'], 'msg-42');
      expect(
        captured.payload.body?['text'],
        'Suggest a response for this message',
      );
    },
  );

  test('sendSuggestionRequest throws when agentDid is not configured', () {
    when(() => core.options).thenReturn(const MeetingPlaceCoreSDKOptions());

    expect(
      () => sdk.sendSuggestionRequest(
        messageId: 'msg-42',
        text: 'Suggest a response for this message',
      ),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('agentDid'),
        ),
      ),
    );
    verifyNever(() => core.sendMessage(any()));
  });
}
