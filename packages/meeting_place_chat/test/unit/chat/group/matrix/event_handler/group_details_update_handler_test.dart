import 'dart:convert';
import 'dart:typed_data';

import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_chat/src/chat/group/event_handler/group_details_update_handler.dart';
import 'package:meeting_place_chat/src/transport/matrix/outgoing/group_details_update_sender.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockCoreSDK extends Mock implements MeetingPlaceCoreSDK {}

class _MockChatRepository extends Mock implements ChatRepository {}

class _FakeChatItem extends Fake implements ChatItem {}

class _FakeChannel extends Fake implements Channel {}

class _MockLogger extends Mock implements MeetingPlaceChatSDKLogger {}

ContactCard _card(String did) =>
    ContactCard(did: did, type: 'human', contactInfo: {'n': did});

Uint8List _cardBytes(String did) =>
    Uint8List.fromList(utf8.encode(jsonEncode(_card(did).toJson())));

Group _initialGroup() => Group(
  id: 'group-1',
  did: 'did:test:group',
  offerLink: 'offer://test',
  created: DateTime.utc(2026, 1, 1),
  ownerDid: 'did:test:alice',
  publicKey: 'pk',
  members: [
    GroupMember.admin(
      did: 'did:test:alice',
      contactCard: _card('did:test:alice'),
    ),
  ],
);

Map<String, dynamic> _memberJson(String did, {String status = 'approved'}) => {
  'did': did,
  'date_added': DateTime.utc(2026, 1, 2).toIso8601String(),
  'status': status,
  'public_key': 'pk-$did',
  'membership_type': 'member',
  'contact_card': _card(did).toJson(),
};

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeChatItem());
    registerFallbackValue(_initialGroup());
    registerFallbackValue(_FakeChannel());
    registerFallbackValue(const MatrixEventMediaReference(''));
  });

  group('GroupDetailsUpdateHandler', () {
    late _MockCoreSDK coreSDK;
    late _MockChatRepository chatRepository;
    late ChatStream stream;
    late Group group;
    final channel = _FakeChannel();

    setUp(() {
      coreSDK = _MockCoreSDK();
      chatRepository = _MockChatRepository();
      stream = ChatStream();
      group = _initialGroup();

      when(() => coreSDK.updateGroup(any())).thenAnswer((_) async {});
      when(
        () => chatRepository.createMessage(any()),
      ).thenAnswer((inv) async => inv.positionalArguments.first as ChatItem);
    });

    GroupDetailsUpdateHandler buildHandler() => GroupDetailsUpdateHandler(
      coreSDK: coreSDK,
      chatRepository: chatRepository,
      streamManager: stream,
      chatId: 'chat-1',
      getGroup: () => group,
      setGroup: (g) => group = g,
      getChannel: () async => channel,
      logger: _MockLogger(),
    );

    test(
      'adds only newly approved members and emits a chat item per new join',
      () async {
        when(() => coreSDK.downloadMedia(any(), any())).thenAnswer((inv) async {
          final ref = inv.positionalArguments[1] as MatrixEventMediaReference;
          if (ref.eventId == '\$bob-card') return _cardBytes('did:test:bob');
          if (ref.eventId == '\$carol-card') {
            return _cardBytes('did:test:carol');
          }
          throw Exception('unknown event');
        });

        final received = <StreamData>[];
        stream.listen(received.add);

        await buildHandler().handle(
          IncomingChatEvent(
            type: ChatEventTypes.groupDetailsUpdate,
            senderDid: 'did:test:alice',
            content: {
              'members': [
                _memberJson('did:test:alice'),
                _memberJson('did:test:bob'),
                _memberJson('did:test:carol', status: 'pendingApproval'),
              ],
              GroupDetailsUpdateSender.contactCardEventIdsKey: {
                'did:test:alice': '\$alice-card',
                'did:test:bob': '\$bob-card',
                'did:test:carol': '\$carol-card',
              },
            },
          ),
        );
        await Future<void>.delayed(Duration.zero);

        // Only Bob is *new and approved*. Carol is new but pendingApproval,
        // Alice is already a member.
        verify(() => chatRepository.createMessage(any())).called(1);

        verify(() => coreSDK.updateGroup(any())).called(1);

        // Group membership replaced with the inbound list (3 members).
        expect(group.members.length, 3);

        final events = received.map((d) => d.event).whereType<ChatEvent>();
        expect(events.whereType<ChatGroupDetailsUpdateEvent>().length, 1);
      },
    );
  });
}
