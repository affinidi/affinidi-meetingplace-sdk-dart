import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockCoreSDK extends Mock implements MeetingPlaceCoreSDK {}

class _MockChatRepository extends Mock implements ChatRepository {}

ContactCard _card(String did) =>
    ContactCard(did: did, type: 'human', contactInfo: {'n': did});

Group _group({GroupStatus status = GroupStatus.created}) => Group(
  id: 'group-1',
  did: 'did:test:group',
  offerLink: 'offer://test',
  created: DateTime.utc(2026, 1, 1),
  ownerDid: 'did:test:alice',
  publicKey: 'pk',
  status: status,
  members: [
    GroupMember.admin(
      did: 'did:test:alice',
      contactCard: _card('did:test:alice'),
    ),
  ],
);

GroupMatrixChatSDK _buildSdk(Group group) => GroupMatrixChatSDK(
  coreSDK: _MockCoreSDK(),
  did: 'did:test:alice',
  otherPartyDid: 'did:test:group',
  mediatorDid: 'did:test:mediator',
  chatRepository: _MockChatRepository(),
  options: MeetingPlaceChatSDKOptions(
    chatPresenceSendInterval: const Duration(hours: 1),
  ),
  group: group,
);

void main() {
  group('GroupMatrixChatSDK assertCanSend (deleted group)', () {
    late GroupMatrixChatSDK sdk;

    setUp(() {
      sdk = _buildSdk(_group(status: GroupStatus.deleted));
    });

    Matcher throwsDeletedStateError() => throwsA(
      isA<StateError>().having(
        (e) => e.message,
        'message',
        contains('group has been deleted'),
      ),
    );

    test('sendTextMessage throws', () {
      expect(() => sdk.sendTextMessage('hi'), throwsDeletedStateError());
    });

    test('sendEffect throws', () {
      expect(() => sdk.sendEffect(Effect.confetti), throwsDeletedStateError());
    });

    test('reactOnMessage throws', () {
      final message = Message(
        chatId: 'chat-1',
        messageId: 'msg-1',
        senderDid: 'did:test:alice',
        value: 'hi',
        isFromMe: true,
        dateCreated: DateTime.utc(2026, 1, 1),
        status: ChatItemStatus.sent,
        attachments: const [],
      );
      expect(
        () => sdk.reactOnMessage(message, reaction: '👍'),
        throwsDeletedStateError(),
      );
    });

    test('sendChatActivity throws', () {
      expect(() => sdk.sendChatActivity(), throwsDeletedStateError());
    });

    test('sendCustomEvent throws', () {
      expect(
        () => sdk.sendCustomEvent(type: 'm.room.message', payload: const {}),
        throwsDeletedStateError(),
      );
    });

    test('proposeProfileUpdate throws', () {
      expect(() => sdk.proposeProfileUpdate(), throwsDeletedStateError());
    });

    test('sendChatContactDetailsUpdate throws', () {
      final conciergeMessage = ConciergeMessage(
        chatId: 'chat-1',
        messageId: 'msg-1',
        senderDid: 'did:test:alice',
        isFromMe: false,
        dateCreated: DateTime.utc(2026, 1, 1),
        status: ChatItemStatus.queued,
        data: const {},
        conciergeType: ConciergeMessageType.permissionToUpdateProfile,
      );
      expect(
        () => sdk.sendChatContactDetailsUpdate(conciergeMessage),
        throwsDeletedStateError(),
      );
    });
  });
}
