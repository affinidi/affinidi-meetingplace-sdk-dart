import 'dart:async';

import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_chat/src/utils/message_utils.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

import 'utils/contact_card_fixture.dart' as fixtures;
import 'utils/sdk.dart';

void main() async {
  late MeetingPlaceCoreSDK aliceSDK;
  late MeetingPlaceCoreSDK bobSDK;
  late MeetingPlaceCoreSDK charlieSDK;

  late DidDocument aliceDidDocument;
  late DidDocument bobDidDocument;
  late DidDocument charlieDidDocument;

  late MeetingPlaceChatSDK aliceChatSDK;
  late MeetingPlaceChatSDK bobChatSDK;

  late ChannelRepository aliceChannelRepository;
  late ChannelRepository bobChannelRepository;
  late ChannelRepository charlieChannelRepository;

  // TODO: move setup to utils to make it reusable across tests
  setUp(() async {
    aliceChannelRepository = initChannelRepository();
    bobChannelRepository = initChannelRepository();
    charlieChannelRepository = initChannelRepository();

    aliceSDK = await initCoreSDKInstance(
      channelRepository: aliceChannelRepository,
    );

    bobSDK = await initCoreSDKInstance(channelRepository: bobChannelRepository);

    charlieSDK = await initCoreSDKInstance(
      channelRepository: charlieChannelRepository,
    );

    final aliceDidManager = await aliceSDK.generateDid();
    aliceDidDocument = await aliceDidManager.getDidDocument();

    final bobDidManager = await bobSDK.generateDid();
    bobDidDocument = await bobDidManager.getDidDocument();

    final charlieDidManager = await charlieSDK.generateDid();
    charlieDidDocument = await charlieDidManager.getDidDocument();

    await Future.wait([
      aliceSDK.mediator.updateAcl(
        ownerDidManager: aliceDidManager,
        acl: AccessListAdd(
          ownerDid: aliceDidDocument.id,
          granteeDids: [bobDidDocument.id, charlieDidDocument.id],
        ),
      ),
      bobSDK.mediator.updateAcl(
        ownerDidManager: bobDidManager,
        acl: AccessListAdd(
          ownerDid: bobDidDocument.id,
          granteeDids: [aliceDidDocument.id],
        ),
      ),
      charlieSDK.mediator.updateAcl(
        ownerDidManager: charlieDidManager,
        acl: AccessListAdd(
          ownerDid: charlieDidDocument.id,
          granteeDids: [aliceDidDocument.id],
        ),
      ),
    ]);

    final aliceCard = fixtures.ContactCardFixture.getContactCardFixture(
      did: aliceDidDocument.id,
      contactInfo: fixtures.ContactCardFixture.alicePrimaryCardInfo,
    );
    final bobCard = fixtures.ContactCardFixture.getContactCardFixture(
      did: bobDidDocument.id,
      contactInfo: fixtures.ContactCardFixture.bobPrimaryCardInfo,
    );
    final charlieCard = fixtures.ContactCardFixture.getContactCardFixture(
      did: charlieDidDocument.id,
      contactInfo: fixtures.ContactCardFixture.charliePrimaryCardInfo,
    );

    aliceChatSDK = await initIndividualChatSDK(
      coreSDK: aliceSDK,
      did: aliceDidDocument.id,
      otherPartyDid: bobDidDocument.id,
      channelRepository: aliceChannelRepository,
      channelCard: aliceCard,
      card: aliceCard,
      otherPartyCard: bobCard,
    );

    bobChatSDK = await initIndividualChatSDK(
      coreSDK: bobSDK,
      did: bobDidDocument.id,
      otherPartyDid: aliceDidDocument.id,
      card: bobCard,
      otherPartyCard: aliceCard,
      channelRepository: bobChannelRepository,
      channelCard: aliceCard,
    );

    await charlieChannelRepository.createChannel(
      Channel(
        offerLink: 'charlie',
        publishOfferDid: '',
        mediatorDid: '',
        permanentChannelDid: charlieDidDocument.id,
        otherPartyPermanentChannelDid: aliceDidDocument.id,
        status: ChannelStatus.inaugurated,
        type: ChannelType.individual,
        contactCard: charlieCard,
        otherPartyContactCard: aliceCard,
      ),
    );
  });

  test('sends chat presence message in configured interval', () async {
    final chatSDKWithReducedInterval = await initIndividualChatSDK(
      coreSDK: aliceSDK,
      did: aliceDidDocument.id,
      otherPartyDid: bobDidDocument.id,
      channelRepository: aliceChannelRepository,
      options: ChatSDKOptions(
        chatPresenceSendInterval: const Duration(seconds: 1),
      ),
    );

    var receivedMessages = 0;
    await bobChatSDK.startChatSession();

    // Consume chat presence messages
    final waitForSubscription = Completer<void>();
    await bobChatSDK.chatStreamSubscription.then((stream) {
      waitForSubscription.complete();
      stream!.listen((data) {
        if (MessageUtils.isType(
          data.plainTextMessage!,
          ChatProtocol.chatPresence,
        )) {
          receivedMessages += 1;
        }
      });
    });

    // Start SDK to send presence messages in interval
    await chatSDKWithReducedInterval.startChatSession();

    await waitForSubscription.future;
    await Future<void>.delayed(const Duration(seconds: 3));

    expect(receivedMessages, greaterThan(1));
  });
}
