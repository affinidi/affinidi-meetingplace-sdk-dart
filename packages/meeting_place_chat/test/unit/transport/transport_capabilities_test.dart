import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

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
  publicKey: 'pk',
  status: GroupStatus.created,
  members: [
    GroupMember.admin(
      did: 'did:test:alice',
      publicKey: 'pk-alice',
      contactCard: _card('did:test:alice'),
    ),
  ],
);

IndividualDidcommChatSDK _buildDidcommSdk() => IndividualDidcommChatSDK(
  coreSDK: _MockCoreSDK(),
  did: 'did:test:alice',
  otherPartyDid: 'did:test:bob',
  mediatorDid: 'did:test:mediator',
  chatRepository: _MockChatRepository(),
  options: MeetingPlaceChatSDKOptions(
    chatPresenceSendInterval: const Duration(hours: 1),
  ),
);

IndividualMatrixChatSDK _buildMatrixSdk() => IndividualMatrixChatSDK(
  coreSDK: _MockCoreSDK(),
  did: 'did:test:alice',
  otherPartyDid: 'did:test:bob',
  mediatorDid: 'did:test:mediator',
  chatRepository: _MockChatRepository(),
  options: MeetingPlaceChatSDKOptions(
    chatPresenceSendInterval: const Duration(hours: 1),
  ),
);

GroupMatrixChatSDK _buildGroupMatrixSdk() => GroupMatrixChatSDK(
  coreSDK: _MockCoreSDK(),
  did: 'did:test:alice',
  otherPartyDid: 'did:test:group',
  mediatorDid: 'did:test:mediator',
  chatRepository: _MockChatRepository(),
  options: MeetingPlaceChatSDKOptions(
    chatPresenceSendInterval: const Duration(hours: 1),
  ),
  group: _group(),
);

void main() {
  group('Chat transport capabilities', () {
    test('DIDComm supports images but not video attachments', () {
      final capabilities = _buildDidcommSdk().capabilities;

      expect(capabilities.supports(ChatFeature.imageAttachments), isTrue);
      expect(capabilities.supports(ChatFeature.videoAttachments), isFalse);
      expect(capabilities.supports(ChatFeature.suggestionRequests), isFalse);
    });

    test('individual Matrix supports both image and video attachments', () {
      final capabilities = _buildMatrixSdk().capabilities;

      expect(capabilities.supports(ChatFeature.imageAttachments), isTrue);
      expect(capabilities.supports(ChatFeature.videoAttachments), isTrue);
      expect(capabilities.supports(ChatFeature.suggestionRequests), isTrue);
    });

    test('group Matrix mirrors Matrix attachment capabilities', () {
      final capabilities = _buildGroupMatrixSdk().capabilities;

      expect(capabilities.supports(ChatFeature.imageAttachments), isTrue);
      expect(capabilities.supports(ChatFeature.videoAttachments), isTrue);
      expect(capabilities.supports(ChatFeature.suggestionRequests), isTrue);
    });
  });
}
