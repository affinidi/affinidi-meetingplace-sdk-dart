// ignore_for_file: invalid_use_of_protected_member

import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_matrix/src/chat/group/group_matrix_chat_sdk.dart';
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

void main() {
  group('GroupMatrixChatSDK.buildChannelNotification', () {
    test('returns GroupChannelNotification with group fields', () {
      final group = _group();
      final sdk = GroupMatrixChatSDK(
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

      final notification = sdk.buildChannelNotification('chat-activity');

      expect(notification, isA<GroupChannelNotification>());
      final groupNotif = notification as GroupChannelNotification;
      expect(groupNotif.offerLink, group.offerLink);
      expect(groupNotif.groupDid, group.did);
      expect(groupNotif.type, 'chat-activity');
    });
  });
}
