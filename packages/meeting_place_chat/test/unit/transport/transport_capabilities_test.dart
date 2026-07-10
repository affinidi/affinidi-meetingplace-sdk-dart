import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockCoreSDK extends Mock implements MeetingPlaceCoreSDK {}

class _MockChatRepository extends Mock implements ChatRepository {}

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

void main() {
  group('Chat transport capabilities', () {
    test('DIDComm supports images but not video attachments', () {
      final capabilities = _buildDidcommSdk().capabilities;

      expect(capabilities.supports(ChatFeature.imageAttachments), isTrue);
      expect(capabilities.supports(ChatFeature.videoAttachments), isFalse);
    });

    test('DIDComm does not support audio/video calling', () {
      final capabilities = _buildDidcommSdk().capabilities;

      expect(capabilities.supports(ChatFeature.audioVideoCalling), isFalse);
    });
  });
}
