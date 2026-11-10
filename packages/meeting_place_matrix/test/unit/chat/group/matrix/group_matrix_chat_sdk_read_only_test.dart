import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_matrix/src/chat/group/group_matrix_chat_sdk.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../fakes/fake_fallbacks.dart';

class _MockCoreSDK extends Mock implements MeetingPlaceCoreSDK {}

class _MockChatRepository extends Mock implements ChatRepository {}

ContactCard _card(String did) =>
    ContactCard(did: did, type: 'human', contactInfo: {'n': did});

Group _group() => Group(
  id: 'group-1',
  did: 'did:test:group',
  offerLink: 'offer://test',
  created: DateTime.utc(2026, 1, 1),
  ownerDid: 'did:test:alice',
  status: GroupStatus.created,
  members: [
    GroupMember.admin(
      did: 'did:test:alice',
      contactCard: _card('did:test:alice'),
    ),
  ],
);

final _channel = Channel(
  offerLink: 'offer://test',
  publishOfferDid: 'did:test:pub',
  mediatorDid: 'did:test:mediator',
  status: ChannelStatus.inaugurated,
  contactCard: _card('did:test:bob'),
  type: ChannelType.group,
  transport: ChannelTransport.matrix,
  isConnectionInitiator: false,
  permanentChannelDid: 'did:test:bob',
  otherPartyPermanentChannelDid: 'did:test:group',
);

Message _message() => Message(
  chatId: 'chat-1',
  messageId: 'msg-1',
  senderDid: 'did:test:bob',
  value: 'hi',
  isFromMe: true,
  dateCreated: DateTime.utc(2026, 1, 1),
  status: ChatItemStatus.sent,
  attachments: const [],
  transportId: r'$event-1',
);

void main() {
  setUpAll(() {
    registerFallbackValue(FakeChannel());
  });

  group('GroupMatrixChatSDK in a chat only its moderators post in', () {
    late _MockCoreSDK coreSDK;
    late GroupMatrixChatSDK sdk;

    setUp(() {
      coreSDK = _MockCoreSDK();
      when(
        () => coreSDK.findChannelByOtherPartyPermanentDid('did:test:group'),
      ).thenAnswer((_) async => _channel);
      when(
        () => coreSDK.canPostInGroup(_channel),
      ).thenAnswer((_) async => false);
      sdk = GroupMatrixChatSDK(
        coreSDK: coreSDK,
        did: 'did:test:bob',
        otherPartyDid: 'did:test:group',
        mediatorDid: 'did:test:mediator',
        chatRepository: _MockChatRepository(),
        options: MeetingPlaceChatSDKOptions(
          chatPresenceSendInterval: const Duration(hours: 1),
        ),
        group: _group(),
        card: _card('did:test:bob'),
      );
    });

    final throwsReadOnly = throwsA(
      isA<MeetingPlaceChatSDKException>().having(
        (e) => e.code,
        'code',
        MeetingPlaceChatSDKErrorCode.operationNotSupported,
      ),
    );

    test('refuses a message', () {
      expect(sdk.sendTextMessage('hi'), throwsReadOnly);
    });

    test('refuses a reaction', () {
      expect(sdk.reactOnMessage(_message(), reaction: '👍'), throwsReadOnly);
    });

    test('refuses an edit', () {
      expect(sdk.editTextMessage(_message(), 'edited'), throwsReadOnly);
    });

    test('refuses a deletion', () {
      expect(sdk.deleteMessage(_message()), throwsReadOnly);
    });

    test('refuses an effect', () {
      expect(sdk.sendEffect(Effect.confetti), throwsReadOnly);
    });

    test('refuses a custom event', () {
      expect(
        sdk.sendCustomEvent(type: 'm.room.message', payload: const {}),
        throwsReadOnly,
      );
    });

    test('refuses contact details', () {
      final conciergeMessage = ConciergeMessage(
        chatId: 'chat-1',
        messageId: 'msg-1',
        senderDid: 'did:test:bob',
        isFromMe: false,
        dateCreated: DateTime.utc(2026, 1, 1),
        status: ChatItemStatus.queued,
        data: const {},
        conciergeType: ConciergeMessageType.permissionToUpdateProfile,
      );
      expect(
        sdk.sendChatContactDetailsUpdate(conciergeMessage),
        throwsReadOnly,
      );
    });
  });
}
