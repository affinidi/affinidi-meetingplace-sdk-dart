import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:test/test.dart';

import '../../utils/fakes.dart';

IndividualChatSDK _makeSdk({
  String did = 'did:key:alice',
  String otherPartyDid = 'did:key:bob',
}) {
  return IndividualChatSDK(
    coreSDK: FakeCoreSDK(),
    did: did,
    otherPartyDid: otherPartyDid,
    mediatorDid: 'did:key:mediator',
    chatRepository: FakeChatRepository(),
    options: ChatSDKOptions(),
  );
}

void main() {
  group('BaseChatSDK.createAttachmentMessage', () {
    test('throws when senderDid is not a channel participant', () async {
      final sdk = _makeSdk();
      expect(
        () => sdk.createAttachmentMessage(
          attachments: [],
          senderDid: 'did:key:attacker',
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('is not a participant'),
          ),
        ),
      );
    });

    test('completes when senderDid equals did (outgoing)', () async {
      final sdk = _makeSdk();
      await expectLater(
        sdk.createAttachmentMessage(
          attachments: [],
          senderDid: 'did:key:alice',
        ),
        completes,
      );
    });

    test('completes when senderDid equals otherPartyDid (incoming)', () async {
      final sdk = _makeSdk();
      await expectLater(
        sdk.createAttachmentMessage(attachments: [], senderDid: 'did:key:bob'),
        completes,
      );
    });
  });
}
