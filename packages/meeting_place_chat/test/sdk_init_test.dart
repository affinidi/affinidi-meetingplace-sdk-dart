import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';

import 'package:ssi/ssi.dart';
import 'package:test/test.dart';
import 'utils/contact_card_fixture.dart';
import 'utils/repository/chat_repository_impl.dart';
import 'utils/repository/connection_group_offer_repository_impl.dart';
import 'utils/sdk.dart';
import 'utils/storage/in_memory_storage.dart';

void main() async {
  late final MeetingPlaceCoreSDK coreSDK;
  late final GroupRepository groupRepository;

  Channel getChannel(ChannelType type) => Channel(
        offerLink: '',
        publishOfferDid: '',
        mediatorDid: '',
        status: ChannelStatus.inaugurated,
        contactCard: ContactCardFixture.getContactCardFixture(
            did: 'did:test', contactInfo: {}),
        type: type,
        permanentChannelDid: 'did:key:123',
        otherPartyPermanentChannelDid: 'did:key:456',
      );

  setUpAll(() async {
    groupRepository = GroupRepositoryImpl(storage: InMemoryStorage());
    coreSDK = await initCoreSDKInstance(
      wallet: PersistentWallet(InMemoryKeyStore()),
      groupRepository: groupRepository,
    );
  });

  test('individual chat SDK instance for channel type individual', () async {
    final channel = getChannel(ChannelType.individual);
    final chatSDK = await MeetingPlaceChatSDK.initialiseFromChannel(
      channel,
      coreSDK: coreSDK,
      chatRepository: ChatRepositoryImpl(storage: InMemoryStorage()),
      options: ChatSDKOptions(),
    );

    expect(chatSDK, isA<MeetingPlaceChatSDK>());
  });

  test('individual chat SDK instance for channel type oob', () async {
    final channel = getChannel(ChannelType.oob);
    final actual = await MeetingPlaceChatSDK.initialiseFromChannel(
      channel,
      coreSDK: coreSDK,
      chatRepository: ChatRepositoryImpl(storage: InMemoryStorage()),
      options: ChatSDKOptions(),
    );

    expect(actual, isA<MeetingPlaceChatSDK>());
  });

  test('group chat SDK instance for channel type group', () async {
    final channel = getChannel(ChannelType.group);

    await groupRepository.createGroup(Group(
      id: channel.permanentChannelDid!,
      did: channel.otherPartyPermanentChannelDid!,
      offerLink: channel.offerLink,
      members: [],
      created: DateTime.now().toUtc(),
    ));

    final actual = await MeetingPlaceChatSDK.initialiseFromChannel(
      channel,
      coreSDK: coreSDK,
      chatRepository: ChatRepositoryImpl(storage: InMemoryStorage()),
      options: ChatSDKOptions(),
    );

    expect(actual, isA<MeetingPlaceChatSDK>());
  });
}
