import 'dart:typed_data';

import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:test/test.dart';

import '../../utils/fakes.dart';

void main() {
  test(
    'refreshCurrentContactCard updates current card and proposes update',
    () async {
      final initialCard = ContactCard(
        did: 'did:test:alice',
        type: 'human',
        contactInfo: const {
          'n': {'given': 'Alice', 'surname': 'Before'},
        },
      );
      final refreshedCard = ContactCard(
        did: 'did:test:alice',
        type: 'human',
        contactInfo: const {
          'n': {'given': 'Alice', 'surname': 'After'},
        },
      );

      final sdk = _TestBaseChatSdk(card: initialCard);

      await sdk.refreshCurrentContactCard(refreshedCard);

      expect(sdk.currentContactCard, isNotNull);
      expect(
        sdk.currentContactCard!.toJson()['contactInfo'],
        equals(refreshedCard.toJson()['contactInfo']),
      );
      expect(sdk.proposeProfileUpdateCallCount, equals(1));
    },
  );
}

class _TestBaseChatSdk extends BaseChatSDK {
  _TestBaseChatSdk({super.card})
    : super(
        coreSDK: FakeCoreSDK(),
        did: 'did:test:alice',
        otherPartyDid: 'did:test:bob',
        mediatorDid: 'did:test:mediator',
        chatRepository: FakeChatRepository(),
        options: MeetingPlaceChatSDKOptions(),
      );

  int proposeProfileUpdateCallCount = 0;

  @override
  Future<Chat> startChatSession() async =>
      Chat(id: chatId, stream: chatStream, messages: const []);

  @override
  Future<void> deleteMessage(Message message, {bool localOnly = false}) async {}

  @override
  Future<Uint8List> downloadMedia(ChatAttachment attachment) async =>
      Uint8List(0);

  @override
  Future<void> editTextMessage(Message message, String newText) async {}

  @override
  Future<List<ChatItem>> get messages async => const [];

  @override
  Future<void> proposeProfileUpdate() async {
    proposeProfileUpdateCallCount += 1;
  }

  @override
  Future<void> reactOnMessage(
    Message message, {
    required String reaction,
  }) async {}

  @override
  Future<void> rejectChatContactDetailsUpdate(ConciergeMessage message) async {}

  @override
  Future<void> sendChatActivity() async {}

  @override
  Future<void> sendChatContactDetailsUpdate(ConciergeMessage message) async {}

  @override
  Future<void> sendChatDeliveredMessage(String messageId) async {}

  @override
  Future<void> sendChatPresence() async {}

  @override
  Future<void> sendEffect(Effect effect) async {}

  @override
  Future<Message> sendTextMessage(
    String text, {
    List<ChatAttachment> attachments = const [],
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> startChatPresenceUpdates() async {}

  Future<void> updateMessage(Message message) async {}
}
