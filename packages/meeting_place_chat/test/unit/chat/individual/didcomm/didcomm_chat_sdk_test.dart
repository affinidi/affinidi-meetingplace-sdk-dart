import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockCoreSDK extends Mock implements MeetingPlaceCoreSDK {}

class _MockChatRepository extends Mock implements ChatRepository {}

const _aliceDid = 'did:test:alice';
const _bobDid = 'did:test:bob';
const _mediatorDid = 'did:test:mediator';

IndividualDidcommChatSDK _buildSdk({
  required _MockCoreSDK core,
  required _MockChatRepository repo,
}) => IndividualDidcommChatSDK(
  coreSDK: core,
  did: _aliceDid,
  otherPartyDid: _bobDid,
  mediatorDid: _mediatorDid,
  chatRepository: repo,
  options: MeetingPlaceChatSDKOptions(
    chatPresenceSendInterval: const Duration(hours: 1),
  ),
);

Channel _fakeChannel() => Channel(
  offerLink: 'https://example.com/offer',
  publishOfferDid: _aliceDid,
  mediatorDid: _mediatorDid,
  status: ChannelStatus.inaugurated,
  contactCard: ContactCard(did: _aliceDid, type: 'individual', contactInfo: {}),
  type: ChannelType.individual,
  isConnectionInitiator: true,
  permanentChannelDid: _aliceDid,
  otherPartyPermanentChannelDid: _bobDid,
);

void main() {
  late _MockCoreSDK core;
  late _MockChatRepository repo;
  late IndividualDidcommChatSDK sdk;

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
    registerFallbackValue(_fakeChannel());
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
  });

  group('deleteMessage', () {
    test('throws UnsupportedError', () {
      final msg = Message(
        chatId: Chat.deriveId(did: _aliceDid, otherPartyDid: _bobDid),
        messageId: 'msg-1',
        senderDid: _aliceDid,
        value: 'hello',
        isFromMe: true,
        dateCreated: DateTime.now().toUtc(),
        status: ChatItemStatus.sent,
      );

      expect(() => sdk.deleteMessage(msg), throwsA(isA<UnsupportedError>()));
    });

    test('throws UnsupportedError with localOnly flag', () {
      final msg = Message(
        chatId: Chat.deriveId(did: _aliceDid, otherPartyDid: _bobDid),
        messageId: 'msg-1',
        senderDid: _aliceDid,
        value: 'hello',
        isFromMe: true,
        dateCreated: DateTime.now().toUtc(),
        status: ChatItemStatus.sent,
      );

      expect(
        () => sdk.deleteMessage(msg, localOnly: true),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });

  group('sendTextMessage', () {
    test('returns sent status even when notification fails', () async {
      when(
        () => core.getChannelByOtherPartyPermanentDid(any()),
      ).thenAnswer((_) async => _fakeChannel());

      when(() => core.sendMessage(any())).thenThrow(
        MeetingPlaceCoreSDKException(
          message: 'Notification failed',
          code: MeetingPlaceCoreSDKErrorCode.channelNotificationFailed.value,
          innerException: Exception('push failed'),
        ),
      );

      when(() => core.updateChannel(any())).thenAnswer((_) async {});

      when(() => repo.createMessage(any())).thenAnswer((inv) async {
        return inv.positionalArguments.first as ChatItem;
      });

      when(() => repo.updateMesssage(any())).thenAnswer((inv) async {
        return inv.positionalArguments.first as ChatItem;
      });

      final result = await sdk.sendTextMessage('Sample text message');
      expect(result.status, ChatItemStatus.sent);
    });

    test('persists message in repository', () async {
      when(
        () => core.getChannelByOtherPartyPermanentDid(any()),
      ).thenAnswer((_) async => _fakeChannel());

      when(() => core.sendMessage(any())).thenAnswer((_) async => 'ok');
      when(() => core.updateChannel(any())).thenAnswer((_) async {});

      when(() => repo.createMessage(any())).thenAnswer((inv) async {
        return inv.positionalArguments.first as ChatItem;
      });

      when(() => repo.updateMesssage(any())).thenAnswer((inv) async {
        return inv.positionalArguments.first as ChatItem;
      });

      final result = await sdk.sendTextMessage('Hello World!');

      expect(result.value, 'Hello World!');
      expect(result.isFromMe, isTrue);
      verify(() => repo.createMessage(any())).called(1);
    });
  });

  group('rejectChatContactDetailsUpdate', () {
    test('sets status to confirmed and persists', () async {
      final concierge = ConciergeMessage(
        chatId: Chat.deriveId(did: _aliceDid, otherPartyDid: _bobDid),
        messageId: 'concierge-1',
        senderDid: _bobDid,
        isFromMe: false,
        dateCreated: DateTime.now().toUtc(),
        status: ChatItemStatus.userInput,
        data: {'profileHash': 'abc123', 'replyTo': _bobDid},
        conciergeType: ConciergeMessageType.permissionToUpdateProfile,
      );

      when(() => repo.updateMesssage(any())).thenAnswer((inv) async {
        return inv.positionalArguments.first as ChatItem;
      });

      await sdk.rejectChatContactDetailsUpdate(concierge);

      expect(concierge.status, ChatItemStatus.confirmed);
      verify(() => repo.updateMesssage(concierge)).called(1);
    });
  });
}
