import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_matrix/src/chat/group/group_matrix_chat_sdk.dart';
import 'package:meeting_place_matrix/src/chat/individual/individual_matrix_chat_sdk.dart';
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

IndividualMatrixChatSDK _buildMatrixSdk(_MockCoreSDK core) =>
    IndividualMatrixChatSDK(
      coreSDK: core,
      did: 'did:test:alice',
      otherPartyDid: 'did:test:bob',
      mediatorDid: 'did:test:mediator',
      chatRepository: _MockChatRepository(),
      options: MeetingPlaceChatSDKOptions(
        chatPresenceSendInterval: const Duration(hours: 1),
      ),
    );

GroupMatrixChatSDK _buildGroupMatrixSdk(_MockCoreSDK core) =>
    GroupMatrixChatSDK(
      coreSDK: core,
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
    test('individual Matrix supports both image and video attachments', () {
      final core = _MockCoreSDK();
      when(() => core.options).thenReturn(const MeetingPlaceCoreSDKOptions());
      final capabilities = _buildMatrixSdk(core).capabilities;

      expect(capabilities.supports(ChatFeature.imageAttachments), isTrue);
      expect(capabilities.supports(ChatFeature.videoAttachments), isTrue);
    });

    test('individual Matrix supports audio/video calling', () {
      final core = _MockCoreSDK();
      when(() => core.options).thenReturn(const MeetingPlaceCoreSDKOptions());
      final capabilities = _buildMatrixSdk(core).capabilities;

      expect(capabilities.supports(ChatFeature.audioVideoCalling), isTrue);
    });

    test(
      'individual Matrix exposes suggestion requests when agentDid exists',
      () {
        final core = _MockCoreSDK();
        when(() => core.options).thenReturn(
          const MeetingPlaceCoreSDKOptions(agentDid: 'did:test:agent'),
        );
        final capabilities = _buildMatrixSdk(core).capabilities;

        expect(capabilities.supports(ChatFeature.suggestionRequests), isTrue);
      },
    );

    test(
      'individual Matrix hides suggestion requests when agentDid is absent',
      () {
        final core = _MockCoreSDK();
        when(() => core.options).thenReturn(const MeetingPlaceCoreSDKOptions());
        final capabilities = _buildMatrixSdk(core).capabilities;

        expect(capabilities.supports(ChatFeature.suggestionRequests), isFalse);
      },
    );

    test('group Matrix mirrors Matrix attachment capabilities', () {
      final core = _MockCoreSDK();
      when(() => core.options).thenReturn(const MeetingPlaceCoreSDKOptions());
      final capabilities = _buildGroupMatrixSdk(core).capabilities;

      expect(capabilities.supports(ChatFeature.imageAttachments), isTrue);
      expect(capabilities.supports(ChatFeature.videoAttachments), isTrue);
    });

    test('group Matrix supports audio/video calling', () {
      final core = _MockCoreSDK();
      when(() => core.options).thenReturn(const MeetingPlaceCoreSDKOptions());
      final capabilities = _buildGroupMatrixSdk(core).capabilities;

      expect(capabilities.supports(ChatFeature.audioVideoCalling), isTrue);
    });

    test('group Matrix exposes suggestion requests when agentDid exists', () {
      final core = _MockCoreSDK();
      when(() => core.options).thenReturn(
        const MeetingPlaceCoreSDKOptions(agentDid: 'did:test:agent'),
      );
      final capabilities = _buildGroupMatrixSdk(core).capabilities;

      expect(capabilities.supports(ChatFeature.suggestionRequests), isTrue);
    });

    test('group Matrix hides suggestion requests when agentDid is absent', () {
      final core = _MockCoreSDK();
      when(() => core.options).thenReturn(const MeetingPlaceCoreSDKOptions());
      final capabilities = _buildGroupMatrixSdk(core).capabilities;

      expect(capabilities.supports(ChatFeature.suggestionRequests), isFalse);
    });
  });
}
