import 'dart:async';

import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../../utils/repository/chat_repository_impl.dart';
import '../../../../utils/storage/in_memory_storage.dart';

class _MockCoreSDK extends Mock implements MeetingPlaceCoreSDK {}

class _MockVdipClient extends Mock implements VdipClient {}

class _FakeIncomingMessageHandle extends Fake implements IncomingMessageHandle {
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

Channel _fakeChannel({int seqNo = 0}) => Channel(
  offerLink: 'https://example.com/offer',
  publishOfferDid: _aliceDid,
  mediatorDid: _mediatorDid,
  status: ChannelStatus.inaugurated,
  contactCard: ContactCard(did: _aliceDid, type: 'individual', contactInfo: {}),
  type: ChannelType.individual,
  isConnectionInitiator: true,
  permanentChannelDid: _aliceDid,
  otherPartyPermanentChannelDid: _bobDid,
  seqNo: seqNo,
);

void main() {
  late _MockCoreSDK core;
  late _MockVdipClient vdip;
  late StreamController<IncomingMessage> incomingController;
  late InMemoryStorage storage;
  late ChatRepositoryImpl repo;
  late IndividualDidcommChatSDK sdk;

  setUpAll(() {
    registerFallbackValue(
      PlainTextMessage(
        id: 'plain-text-fallback',
        type: Uri.parse('https://example.com/fallback'),
        body: const {},
      ),
    );
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
    registerFallbackValue(
      const DidCommSubscription(receiverDid: '', mediatorDid: ''),
    );
    registerFallbackValue(_fakeChannel());
  });

  setUp(() {
    core = _MockCoreSDK();
    vdip = _MockVdipClient();
    incomingController = StreamController<IncomingMessage>.broadcast();
    storage = InMemoryStorage();
    repo = ChatRepositoryImpl(storage: storage);

    when(
      () => core.subscribe(any()),
    ).thenAnswer((_) async => _FakeIncomingMessageHandle(incomingController));
    when(
      () => core.getChannelByOtherPartyPermanentDid(any()),
    ).thenAnswer((_) async => _fakeChannel());
    when(() => core.vdip).thenReturn(vdip);
    when(() => vdip.dispatch(any())).thenReturn(null);
    when(() => core.sendMessage(any())).thenAnswer((_) async => 'ok');
    when(() => core.updateChannel(any())).thenAnswer((_) async {});

    sdk = IndividualDidcommChatSDK(
      coreSDK: core,
      did: _aliceDid,
      otherPartyDid: _bobDid,
      mediatorDid: _mediatorDid,
      chatRepository: repo,
      options: MeetingPlaceChatSDKOptions(
        chatPresenceSendInterval: const Duration(hours: 1),
      ),
    );
  });

  tearDown(() async {
    await sdk.endChatSession();
    if (!incomingController.isClosed) {
      await incomingController.close();
    }
  });

  group('sendCustomEvent', () {
    test('calls core.sendMessage with correct type and payload', () async {
      await sdk.startChatSession();

      await sdk.sendCustomEvent(
        type: ChatProtocol.chatMessage.value,
        payload: {
          'text': 'Hello via custom',
          'seq_no': 1,
          'timestamp': DateTime.utc(2026).toIso8601String(),
        },
      );

      final captured =
          verify(() => core.sendMessage(captureAny())).captured.last
              as DidCommOutgoingMessage;
      expect(captured.senderDid, _aliceDid);
      expect(captured.recipientDid, _bobDid);
      expect(captured.payload.type.toString(), ChatProtocol.chatMessage.value);
      expect(captured.payload.body?['text'], 'Hello via custom');
    });
  });

  group('incoming message handling', () {
    test('incoming chat message is persisted and emitted on stream', () async {
      final chat = await sdk.startChatSession();

      final eventFuture = chat.stream!.stream
          .where((d) => d.event is ChatMessageEvent)
          .first;

      incomingController.add(
        DidCommIncomingMessage(
          senderDid: _bobDid,
          timestamp: DateTime.utc(2026),
          payload: PlainTextMessage(
            id: 'msg-incoming-1',
            type: Uri.parse(ChatProtocol.chatMessage.value),
            from: _bobDid,
            to: [_aliceDid],
            body: {
              'text': 'Hello Alice!',
              'seq_no': 1,
              'timestamp': DateTime.utc(2026).toIso8601String(),
            },
            createdTime: DateTime.utc(2026),
          ),
        ),
      );

      final streamData = await eventFuture;
      expect(streamData.event, isA<ChatMessageEvent>());
      expect(streamData.chatItem, isA<Message>());
      expect((streamData.chatItem! as Message).value, 'Hello Alice!');

      final messages = await sdk.messages;
      expect(messages.length, 1);
      expect((messages.first as Message).value, 'Hello Alice!');
      expect((messages.first as Message).status, ChatItemStatus.received);
    });

    test('delivery notification updates message status to delivered', () async {
      final chatId = Chat.deriveId(did: _aliceDid, otherPartyDid: _bobDid);
      await repo.createMessage(
        Message(
          chatId: chatId,
          messageId: 'msg-sent-1',
          senderDid: _aliceDid,
          value: 'Hello Bob!',
          isFromMe: true,
          dateCreated: DateTime.utc(2026),
          status: ChatItemStatus.sent,
        ),
      );

      final chat = await sdk.startChatSession();

      final deliveredFuture = chat.stream!.stream
          .where((d) => d.event is ChatMessageDeliveredEvent)
          .first;

      incomingController.add(
        DidCommIncomingMessage(
          senderDid: _bobDid,
          timestamp: DateTime.utc(2026),
          payload: PlainTextMessage(
            id: 'delivery-ack-1',
            type: Uri.parse(ChatProtocol.chatDelivered.value),
            from: _bobDid,
            to: [_aliceDid],
            body: {
              'messages': ['msg-sent-1'],
            },
            createdTime: DateTime.utc(2026),
          ),
        ),
      );

      final streamData = await deliveredFuture;
      final event = streamData.event as ChatMessageDeliveredEvent;
      expect(event.messageIds, contains('msg-sent-1'));

      final messages = await sdk.messages;
      expect((messages.first as Message).status, ChatItemStatus.delivered);
    });

    test('incoming message with higher seqNo updates channel', () async {
      when(
        () => core.getChannelByOtherPartyPermanentDid(any()),
      ).thenAnswer((_) async => _fakeChannel(seqNo: 5));

      final chat = await sdk.startChatSession();

      final eventFuture = chat.stream!.stream
          .where((d) => d.event is ChatMessageEvent)
          .first;

      incomingController.add(
        DidCommIncomingMessage(
          senderDid: _bobDid,
          timestamp: DateTime.utc(2026),
          payload: PlainTextMessage(
            id: 'msg-seq-high',
            type: Uri.parse(ChatProtocol.chatMessage.value),
            from: _bobDid,
            to: [_aliceDid],
            body: {
              'text': 'Higher seqNo',
              'seq_no': 7,
              'timestamp': DateTime.utc(2026).toIso8601String(),
            },
            createdTime: DateTime.utc(2026),
          ),
        ),
      );

      await eventFuture;

      final captured =
          verify(() => core.updateChannel(captureAny())).captured.last
              as Channel;
      expect(captured.seqNo, 7);
    });

    test('incoming message with lower seqNo does not update channel', () async {
      when(
        () => core.getChannelByOtherPartyPermanentDid(any()),
      ).thenAnswer((_) async => _fakeChannel(seqNo: 10));

      final chat = await sdk.startChatSession();

      final eventFuture = chat.stream!.stream
          .where((d) => d.event is ChatMessageEvent)
          .first;

      incomingController.add(
        DidCommIncomingMessage(
          senderDid: _bobDid,
          timestamp: DateTime.utc(2026),
          payload: PlainTextMessage(
            id: 'msg-seq-low',
            type: Uri.parse(ChatProtocol.chatMessage.value),
            from: _bobDid,
            to: [_aliceDid],
            body: {
              'text': 'Lower seqNo',
              'seq_no': 3,
              'timestamp': DateTime.utc(2026).toIso8601String(),
            },
            createdTime: DateTime.utc(2026),
          ),
        ),
      );

      await eventFuture;

      verifyNever(() => core.updateChannel(any()));
    });

    test('incoming issued credential emits ChatIssuedCredentialEvent', () async {
      final chat = await sdk.startChatSession();

      final eventFuture = chat.stream!.stream
          .where((d) => d.event is ChatIssuedCredentialEvent)
          .first;

      incomingController.add(
        DidCommIncomingMessage(
          senderDid: _bobDid,
          timestamp: DateTime.utc(2026),
          payload: PlainTextMessage(
            id: 'issued-credential-1',
            type: Uri.parse(VdipClient.issuedCredentialMessageType),
            from: _bobDid,
            to: [_aliceDid],
            body: {
              'credential': 'eyJ2YyI6InRlc3QifQ==',
            },
            createdTime: DateTime.utc(2026),
          ),
        ),
      );

      final streamData = await eventFuture;
      final event = streamData.event as ChatIssuedCredentialEvent;
      expect(event.senderDid, _bobDid);
      expect(event.body['credential'], 'eyJ2YyI6InRlc3QifQ==');
      verify(() => vdip.dispatch(any())).called(1);
    });
  });
}
