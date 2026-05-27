import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_chat/src/chat/base_chat_sdk.dart';
import 'package:meeting_place_chat/src/chat/group/event_handler/contact_details_update_handler.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockBaseChatSDK extends Mock implements BaseChatSDK {}

class _MockCoreSDK extends Mock implements MeetingPlaceCoreSDK {}

ContactCard _card(String did, {String name = 'Original'}) => ContactCard(
  did: did,
  type: 'human',
  contactInfo: {'n': name},
);

Group _group() => Group(
  id: 'group-1',
  did: 'did:test:group',
  offerLink: 'offer://test',
  created: DateTime.utc(2026, 1, 1),
  ownerDid: 'did:test:alice',
  publicKey: 'pk',
  members: [
    GroupMember.admin(
      did: 'did:test:alice',
      publicKey: 'pk',
      contactCard: _card('did:test:alice'),
    ),
    GroupMember(
      did: 'did:test:bob',
      publicKey: 'pk-bob',
      dateAdded: DateTime.utc(2026, 1, 1),
      status: GroupMemberStatus.approved,
      membershipType: GroupMembershipType.member,
      contactCard: _card('did:test:bob'),
    ),
  ],
);

void main() {
  setUpAll(() => registerFallbackValue(_group()));

  group('ContactDetailsUpdateHandler', () {
    late _MockBaseChatSDK chatSDK;
    late _MockCoreSDK coreSDK;
    late ChatStream stream;
    late Group group;

    setUp(() {
      chatSDK = _MockBaseChatSDK();
      coreSDK = _MockCoreSDK();
      stream = ChatStream();
      group = _group();

      when(() => chatSDK.coreSDK).thenReturn(coreSDK);
      when(() => coreSDK.updateGroup(any())).thenAnswer((_) async {});
    });

    ContactDetailsUpdateHandler buildHandler() => ContactDetailsUpdateHandler(
      chatSDK: chatSDK,
      streamManager: stream,
      getGroup: () => group,
      setGroup: (g) => group = g,
    );

    test('updates member contact card and emits ChatContactDetailsUpdateEvent',
        () async {
      final received = <StreamData>[];
      stream.listen(received.add);

      final newCard = _card('did:test:bob', name: 'Robert');

      await buildHandler().handle(
        IncomingChatEvent(
          type: ChatEventTypes.contactDetailsUpdate,
          senderDid: 'did:test:bob',
          content: {'profileDetails': newCard.toJson()},
        ),
      );
      await Future<void>.delayed(Duration.zero);

      final bob = group.members.firstWhere((m) => m.did == 'did:test:bob');
      expect(bob.contactCard.contactInfo['n'], 'Robert');
      verify(() => coreSDK.updateGroup(any())).called(1);
      expect(received.length, 1);
      expect(received.single.event, isA<ChatContactDetailsUpdateEvent>());
    });

    test('does nothing when senderDid is null', () async {
      await buildHandler().handle(
        IncomingChatEvent(
          type: ChatEventTypes.contactDetailsUpdate,
          senderDid: null,
          content: {'profileDetails': _card('x').toJson()},
        ),
      );
      verifyNever(() => coreSDK.updateGroup(any()));
    });

    test('does nothing when profileDetails is missing', () async {
      await buildHandler().handle(
        IncomingChatEvent(
          type: ChatEventTypes.contactDetailsUpdate,
          senderDid: 'did:test:bob',
          content: const {},
        ),
      );
      verifyNever(() => coreSDK.updateGroup(any()));
    });

    test('does nothing when sender is not a group member', () async {
      await buildHandler().handle(
        IncomingChatEvent(
          type: ChatEventTypes.contactDetailsUpdate,
          senderDid: 'did:test:stranger',
          content: {'profileDetails': _card('did:test:stranger').toJson()},
        ),
      );
      verifyNever(() => coreSDK.updateGroup(any()));
    });
  });
}
