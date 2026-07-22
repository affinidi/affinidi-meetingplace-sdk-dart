import 'dart:async';

import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../../utils/repository/chat_repository_impl.dart';
import '../../../../utils/storage/in_memory_storage.dart';

class _MockCoreSDK extends Mock implements MeetingPlaceCoreSDK {}

class _MockVdipClient extends Mock implements VdipClient {}

class _MockCoreSDKStreamSubscription extends Mock
    implements
        CoreSDKStreamSubscription<
          MediatorMessage,
          MediatorStreamProcessingResult
        > {}

class _FakeIncomingMessageHandle implements IncomingMessageHandle {
  _FakeIncomingMessageHandle(this._controller);

  final StreamController<IncomingMessage> _controller;

  @override
  Stream<IncomingMessage> get stream => _controller.stream;

  @override
  Future<void> dispose() async {
    await _controller.close();
  }
}

const _aliceDid = 'did:test:alice';
const _bobDid = 'did:test:bob';
const _mediatorDid = 'did:test:mediator';

Channel _channel() => Channel(
  offerLink: 'offer://individual',
  publishOfferDid: _aliceDid,
  mediatorDid: _mediatorDid,
  status: ChannelStatus.inaugurated,
  contactCard: ContactCard(did: _aliceDid, type: 'human', contactInfo: {}),
  type: ChannelType.individual,
  isConnectionInitiator: true,
  permanentChannelDid: _aliceDid,
  otherPartyPermanentChannelDid: _bobDid,
);

void main() {
  setUpAll(() {
    registerFallbackValue(
      const MatrixRoomSubscription(
        receiverDid: '',
        options: MatrixSubscriptionOptions(excludeSelf: true),
      ),
    );
    registerFallbackValue(
      const DidCommSubscription(receiverDid: '', mediatorDid: ''),
    );
    registerFallbackValue(_channel());
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

  test(
    'IndividualMatrixChatSDK persists mediator DIDComm chat messages',
    () async {
      final core = _MockCoreSDK();
      final vdip = _MockVdipClient();
      final vdipSubscription = _MockCoreSDKStreamSubscription();
      final incomingController = StreamController<IncomingMessage>.broadcast();
      final repo = ChatRepositoryImpl(storage: InMemoryStorage());

      when(
        () => core.subscribe(any()),
      ).thenAnswer((_) async => _FakeIncomingMessageHandle(incomingController));
      when(() => core.vdip).thenReturn(vdip);
      when(
        () => vdip.subscribe(any()),
      ).thenAnswer((_) async => vdipSubscription);
      when(() => vdip.incomingMessages).thenAnswer((_) => const Stream.empty());
      when(vdip.unsubscribe).thenAnswer((_) async {});
      when(
        () => core.getChannelByOtherPartyPermanentDid(_bobDid),
      ).thenAnswer((_) async => _channel());
      when(() => core.sendMessage(any())).thenAnswer((_) async => 'ok');
      when(() => core.updateChannel(any())).thenAnswer((_) async {});

      final sdk = IndividualMatrixChatSDK(
        coreSDK: core,
        did: _aliceDid,
        otherPartyDid: _bobDid,
        mediatorDid: _mediatorDid,
        chatRepository: repo,
        options: MeetingPlaceChatSDKOptions(
          chatPresenceSendInterval: const Duration(hours: 1),
        ),
      );

      final chat = await sdk.startChatSession();
      await Future<void>.delayed(Duration.zero);
      final eventFuture = chat.stream!.stream
          .where((d) => d.event is ChatMessageEvent)
          .first;

      incomingController.add(
        DidCommIncomingMessage(
          senderDid: _bobDid,
          timestamp: DateTime.utc(2026),
          payload: PlainTextMessage(
            id: 'mediator-msg-1',
            type: Uri.parse(ChatProtocol.chatMessage.value),
            from: _bobDid,
            to: [_aliceDid],
            body: {
              'text': 'Hello through mediator',
              'seq_no': 1,
              'timestamp': DateTime.utc(2026).toIso8601String(),
            },
            createdTime: DateTime.utc(2026),
          ),
        ),
      );

      final streamData = await eventFuture;
      expect((streamData.chatItem! as Message).value, 'Hello through mediator');

      final messages = await sdk.messages;
      expect(messages, hasLength(1));
      expect((messages.single as Message).messageId, 'mediator-msg-1');

      await sdk.endChatSession();
      if (!incomingController.isClosed) {
        await incomingController.close();
      }
    },
  );
}
