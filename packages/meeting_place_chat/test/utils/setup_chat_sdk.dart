import 'dart:async';

import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';

import 'repository/chat_repository_impl.dart';
import 'sdk.dart';
import 'storage/in_memory_storage.dart';
import 'storage/storage.dart';

class SDKInstance {
  SDKInstance({
    required this.coreSDK,
    required this.didManager,
    required this.didDocument,
    required this.channelRepository,
    required this.contactCard,
  });

  final MeetingPlaceCoreSDK coreSDK;
  final DidManager didManager;
  final DidDocument didDocument;
  final ChannelRepository channelRepository;
  final ContactCard contactCard;
}

class SetupChatSdk {
  Future<SDKInstance> createCoreSDK(Map<String, dynamic> contactInfo) async {
    final channelRepository = initChannelRepository();
    final coreSDK = await initCoreSDKInstance(
      channelRepository: channelRepository,
    );

    final didManager = await coreSDK.generateDid();
    final didDocument = await didManager.getDidDocument();

    return SDKInstance(
      coreSDK: coreSDK,
      didManager: didManager,
      didDocument: didDocument,
      channelRepository: channelRepository,
      contactCard: ContactCard(
        did: didDocument.id,
        type: 'individual',
        contactInfo: contactInfo,
      ),
    );
  }

  /// Runs the real offer/accept/approve handshake between [aliceSDK]
  /// and [bobSDK]. Returns the two inaugurated channels (Alice's view first).
  /// After completion the chat-layer transport (matrix room or DIDComm chat
  /// thread) exists and chat SDKs can be built via
  /// [MeetingPlaceChatSDK.initialiseFromChannel].
  ///
  /// Pass [transport] to select the channel transport. Defaults to
  /// [ChannelTransport.didcomm] to match [MeetingPlaceCoreSDK.publishOffer].
  Future<(Channel aliceChannel, Channel bobChannel)>
  establishIndividualConnection({
    required SDKInstance aliceSDK,
    required SDKInstance bobSDK,
    ChannelTransport transport = ChannelTransport.didcomm,
  }) async {
    final offer = await aliceSDK.coreSDK.publishOffer(
      offerName: 'Sample Offer',
      offerDescription: 'Sample offer description',
      contactCard: aliceSDK.contactCard,
      type: SDKConnectionOfferType.invitation,
      transport: transport,
    );

    final findOfferResult = await bobSDK.coreSDK.findOffer(
      mnemonic: offer.connectionOffer.mnemonic,
    );
    await bobSDK.coreSDK.acceptOffer(
      connectionOffer: findOfferResult.connectionOffer!,
      contactCard: bobSDK.contactCard,
      senderInfo: 'Bob',
    );

    final waitForInvitationAccept = Completer<Channel>();
    final aliceSub = aliceSDK.coreSDK.controlPlaneEventsStream
        .where((e) => e.matchesType(ControlPlaneEventType.InvitationAccept))
        .listen((e) {
          if (!waitForInvitationAccept.isCompleted) {
            waitForInvitationAccept.complete(e.channel);
          }
        });

    final waitForOfferFinalised = Completer<Channel>();
    final bobSub = bobSDK.coreSDK.controlPlaneEventsStream
        .where((e) => e.matchesType(ControlPlaneEventType.OfferFinalised))
        .listen((e) {
          if (!waitForOfferFinalised.isCompleted) {
            waitForOfferFinalised.complete(e.channel);
          }
        });

    await aliceSDK.coreSDK.processControlPlaneEvents();
    final invitationChannel = await waitForInvitationAccept.future;

    final aliceChannel = await aliceSDK.coreSDK.approveConnectionRequest(
      channel: invitationChannel,
    );

    await bobSDK.coreSDK.processControlPlaneEvents();
    final bobChannel = await waitForOfferFinalised.future;

    await aliceSub.cancel();
    await bobSub.cancel();

    return (aliceChannel, bobChannel);
  }

  /// Builds a chat SDK against an already-established [channel] (typically
  /// produced by [establishIndividualConnection]). Delegates to
  /// [MeetingPlaceChatSDK.initialiseFromChannel] — the production factory.
  Future<MeetingPlaceChatSDK> createChatSdk({
    required SDKInstance sdkInstance,
    required Channel channel,
    Storage? storage,
    ContactCard? card,
    MeetingPlaceChatSDKOptions? options,
  }) async {
    final chatStorage = storage ?? InMemoryStorage();
    return MeetingPlaceChatSDK.initialiseFromChannel(
      channel,
      coreSDK: sdkInstance.coreSDK,
      chatRepository: ChatRepositoryImpl(storage: chatStorage),
      card: card ?? sdkInstance.contactCard,
      options:
          options ??
          MeetingPlaceChatSDKOptions(
            chatPresenceSendInterval: const Duration(seconds: 3),
          ),
    );
  }
}
