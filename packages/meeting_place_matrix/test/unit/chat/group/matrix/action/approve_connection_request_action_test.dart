import 'dart:typed_data';

import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_matrix/meeting_place_matrix.dart';
import 'package:meeting_place_matrix/src/chat/group/action/approve_connection_request_action.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockChatSDK extends Mock implements GroupMatrixChatSDK {}

class _MockCoreSDK extends Mock implements MeetingPlaceCoreSDK {}

class _MockChatRepository extends Mock implements ChatRepository {}

class _MockLogger extends Mock implements MeetingPlaceChatSDKLogger {}

class _FakeChannel extends Fake implements Channel {}

class _FakeChatItem extends Fake implements ChatItem {}

class _FakeOutgoingMessage extends Fake implements OutgoingMessage {}

ContactCard _card(String did) =>
    ContactCard(did: did, type: 'human', contactInfo: {'n': did});

Channel _bobChannel() => Channel(
  offerLink: 'offer://bob',
  publishOfferDid: 'did:test:publish',
  mediatorDid: 'did:test:mediator',
  status: ChannelStatus.inaugurated,
  contactCard: _card('did:test:bob'),
  type: ChannelType.group,
  transport: ChannelTransport.matrix,
  isConnectionInitiator: false,
  permanentChannelDid: 'did:test:bob-channel',
  otherPartyPermanentChannelDid: 'did:test:bob',
  otherPartyContactCard: _card('did:test:bob'),
);

Channel _groupChannel() => Channel(
  offerLink: 'offer://group',
  publishOfferDid: 'did:test:publish',
  mediatorDid: 'did:test:mediator',
  status: ChannelStatus.inaugurated,
  contactCard: _card('did:test:group'),
  type: ChannelType.group,
  transport: ChannelTransport.matrix,
  isConnectionInitiator: true,
  permanentChannelDid: 'did:test:alice-channel',
  otherPartyPermanentChannelDid: 'did:test:group',
);

Group _group() => Group(
  id: 'group-1',
  did: 'did:test:group',
  offerLink: 'offer://group',
  created: DateTime.utc(2026, 1, 1),
  ownerDid: 'did:test:alice',
  publicKey: 'pk',
  members: [
    GroupMember.admin(
      did: 'did:test:alice',
      publicKey: 'pk-alice',
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

ConciergeMessage _conciergeMessage() => ConciergeMessage(
  chatId: 'chat-1',
  messageId: 'msg-1',
  senderDid: 'did:test:bob',
  isFromMe: false,
  dateCreated: DateTime.utc(2026, 1, 1),
  status: ChatItemStatus.queued,
  data: {'memberDid': 'did:test:bob'},
  conciergeType: ConciergeMessageType.permissionToJoinGroup,
);

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeChannel());
    registerFallbackValue(_FakeChatItem());
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(_FakeOutgoingMessage());
  });

  group('ApproveConnectionRequestAction', () {
    late _MockChatSDK chatSDK;
    late _MockCoreSDK coreSDK;
    late _MockChatRepository chatRepository;
    late _MockLogger logger;
    late ChatStream chatStream;

    setUp(() {
      chatSDK = _MockChatSDK();
      coreSDK = _MockCoreSDK();
      chatRepository = _MockChatRepository();
      logger = _MockLogger();
      chatStream = ChatStream();

      when(() => chatSDK.coreSDK).thenReturn(coreSDK);
      when(() => chatSDK.chatRepository).thenReturn(chatRepository);
      when(() => chatSDK.chatStream).thenReturn(chatStream);
      when(() => chatSDK.chatId).thenReturn('chat-1');
      when(() => chatSDK.logger).thenReturn(logger);
      when(() => chatSDK.group).thenReturn(_group());
      when(() => chatSDK.did).thenReturn('did:test:alice');
      when(() => chatSDK.getChannel()).thenAnswer((_) async => _groupChannel());

      when(
        () => coreSDK.getChannelByOtherPartyPermanentDid(any()),
      ).thenAnswer((_) async => _bobChannel());
      when(
        () => coreSDK.approveConnectionRequest(channel: any(named: 'channel')),
      ).thenAnswer((_) async => _bobChannel());
      when(() => coreSDK.getGroupById(any())).thenAnswer((_) async => _group());
      when(
        () => coreSDK.sendMediaMessage(
          any(),
          any(),
          contentType: any(named: 'contentType'),
          filename: any(named: 'filename'),
          extraContent: any(named: 'extraContent'),
        ),
      ).thenAnswer((_) async => 'evt-1');
      when(() => coreSDK.sendMessage(any())).thenAnswer((_) async => null);

      when(
        () => chatRepository.createMessage(any()),
      ).thenAnswer((inv) async => inv.positionalArguments.first as ChatItem);
      when(
        () => chatRepository.updateMesssage(any()),
      ).thenAnswer((inv) async => inv.positionalArguments.first as ChatItem);
    });

    test('emits ChatGroupDetailsUpdateEvent so app refreshes group state '
        'before the new member can send any events', () async {
      when(() => chatSDK.isGroupOwner).thenReturn(true);

      final received = <StreamData>[];
      chatStream.listen(received.add);

      await ApproveConnectionRequestAction(
        chatSDK,
        message: _conciergeMessage(),
      ).execute();
      await Future<void>.delayed(Duration.zero);

      expect(
        received.any((d) => d.event is ChatGroupDetailsUpdateEvent),
        isTrue,
      );
    });

    test('non-owner: logs error, throws, and does not call coreSDK', () async {
      when(() => chatSDK.isGroupOwner).thenReturn(false);

      await expectLater(
        () => ApproveConnectionRequestAction(
          chatSDK,
          message: _conciergeMessage(),
        ).execute(),
        throwsException,
      );

      verify(
        () => logger.error(any(), name: 'approveConnectionRequest'),
      ).called(1);
      verifyNever(
        () => coreSDK.approveConnectionRequest(channel: any(named: 'channel')),
      );
    });

    test('channel not found: throws and does not approve', () async {
      when(() => chatSDK.isGroupOwner).thenReturn(true);
      when(
        () => coreSDK.getChannelByOtherPartyPermanentDid(any()),
      ).thenAnswer((_) async => null);

      await expectLater(
        () => ApproveConnectionRequestAction(
          chatSDK,
          message: _conciergeMessage(),
        ).execute(),
        throwsException,
      );

      verifyNever(
        () => coreSDK.approveConnectionRequest(channel: any(named: 'channel')),
      );
    });
  });
}
