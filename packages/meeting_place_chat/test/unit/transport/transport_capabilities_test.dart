import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockCoreSDK extends Mock implements MeetingPlaceCoreSDK {}

class _MockChatRepository extends Mock implements ChatRepository {}

_MockCoreSDK _buildCore({
  MeetingPlaceCoreSDKOptions options = const MeetingPlaceCoreSDKOptions(),
}) {
  final core = _MockCoreSDK();
  when(() => core.options).thenReturn(options);
  return core;
}

IndividualDidcommChatSDK _buildDidcommSdk(_MockCoreSDK core) =>
    IndividualDidcommChatSDK(
      coreSDK: core,
      did: 'did:test:alice',
      otherPartyDid: 'did:test:bob',
      mediatorDid: 'did:test:mediator',
      chatRepository: _MockChatRepository(),
      options: MeetingPlaceChatSDKOptions(
        chatPresenceSendInterval: const Duration(hours: 1),
      ),
    );

void main() {
  group('Chat transport capabilities', () {
    test('DIDComm supports images but not video attachments', () {
      final core = _buildCore();
      final capabilities = _buildDidcommSdk(core).capabilities;

      expect(capabilities.supports(ChatFeature.imageAttachments), isTrue);
      expect(capabilities.supports(ChatFeature.videoAttachments), isFalse);
    });

    test('DIDComm does not support audio/video calling', () {
      final core = _buildCore();
      final capabilities = _buildDidcommSdk(core).capabilities;

      expect(capabilities.supports(ChatFeature.audioVideoCalling), isFalse);
    });

    test(
      'individual DIDComm exposes suggestion requests when agentDid exists',
      () {
        final core = _buildCore(
          options: const MeetingPlaceCoreSDKOptions(agentDid: 'did:test:agent'),
        );
        final capabilities = _buildDidcommSdk(core).capabilities;

        expect(capabilities.supports(ChatFeature.suggestionRequests), isTrue);
      },
    );

    test(
      'individual DIDComm hides suggestion requests when agentDid is absent',
      () {
        final core = _buildCore();
        final capabilities = _buildDidcommSdk(core).capabilities;

        expect(capabilities.supports(ChatFeature.suggestionRequests), isFalse);
      },
    );
  });
}
