import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_matrix/src/chat/group/action/propose_profile_update_action.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../../fakes/fake_fallbacks.dart';
import '../../../../mocks/mocks.dart';

ContactCard _card(String surname) => ContactCard(
  did: 'did:test:bob',
  type: 'human',
  contactInfo: {
    'n': {'given': 'Bob', 'surname': surname},
  },
);

Channel _channel(ContactCard card) => Channel(
  offerLink: 'offer://group',
  publishOfferDid: 'did:test:publish',
  mediatorDid: 'did:test:mediator',
  status: ChannelStatus.inaugurated,
  contactCard: card,
  type: ChannelType.group,
  transport: ChannelTransport.matrix,
  isConnectionInitiator: true,
  permanentChannelDid: 'did:test:bob',
  otherPartyPermanentChannelDid: 'did:test:group',
);

ConciergeMessage _pendingProfileUpdate(ContactCard card) => ConciergeMessage(
  chatId: 'chat-1',
  messageId: 'msg-1',
  senderDid: 'did:test:bob',
  isFromMe: false,
  dateCreated: DateTime.utc(2026, 1, 1),
  status: ChatItemStatus.userInput,
  conciergeType: ConciergeMessageType.permissionToUpdateProfile,
  data: {'profileDetails': card.toJson()},
);

void main() {
  setUpAll(() {
    registerFallbackValue(FakeChannel());
    registerFallbackValue(FakeChatItem());
  });

  group('ProposeProfileUpdateAction', () {
    late MockGroupMatrixChatSDK chatSDK;
    late MockMeetingPlaceCoreSDK coreSDK;
    late MockChatRepository chatRepository;
    late MockMeetingPlaceChatSDKLogger logger;
    late ChatStream chatStream;

    setUp(() {
      chatSDK = MockGroupMatrixChatSDK();
      coreSDK = MockMeetingPlaceCoreSDK();
      chatRepository = MockChatRepository();
      logger = MockMeetingPlaceChatSDKLogger();
      chatStream = ChatStream();

      when(() => chatSDK.coreSDK).thenReturn(coreSDK);
      when(() => chatSDK.chatRepository).thenReturn(chatRepository);
      when(() => chatSDK.chatStream).thenReturn(chatStream);
      when(() => chatSDK.chatId).thenReturn('chat-1');
      when(() => chatSDK.did).thenReturn('did:test:bob');
      when(() => chatSDK.logger).thenReturn(logger);
      when(() => logger.info(any(), name: any(named: 'name'))).thenReturn(null);
      when(
        () => logger.warning(any(), name: any(named: 'name')),
      ).thenReturn(null);
      when(() => coreSDK.updateChannel(any())).thenAnswer((_) async {});
      when(
        () => chatRepository.updateMesssage(any()),
      ).thenAnswer((inv) async => inv.positionalArguments.first as ChatItem);
      when(
        () => chatRepository.createMessage(any()),
      ).thenAnswer((inv) async => inv.positionalArguments.first as ChatItem);
    });

    test(
      'updates an existing pending concierge with the current card',
      () async {
        final staleCard = _card('Stale');
        final freshCard = _card('Fresh');
        final existing = _pendingProfileUpdate(staleCard);
        final emitted = <StreamData>[];
        chatStream.listen(emitted.add);

        when(() => chatSDK.currentContactCard).thenReturn(freshCard);
        when(
          () => chatSDK.getChannel(),
        ).thenAnswer((_) async => _channel(staleCard));
        when(
          () => chatRepository.listMessages('chat-1'),
        ).thenAnswer((_) async => [existing]);

        await ProposeProfileUpdateAction(chatSDK).execute();
        await Future<void>.delayed(Duration.zero);

        expect(existing.data['profileDetails'], equals(freshCard.toJson()));
        verify(() => chatRepository.updateMesssage(existing)).called(1);
        verifyNever(() => chatRepository.createMessage(any()));
        expect(emitted.single.chatItem, same(existing));
      },
    );
  });
}
