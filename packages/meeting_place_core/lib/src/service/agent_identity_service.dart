import 'package:ssi/ssi.dart';

import '../../meeting_place_core.dart';
import '../protocol/message/agent_create_channel_identity_response/agent_create_channel_identity_response.dart';
import 'identity/identity_service.dart';
import 'mediator/mediator_acl_service.dart';

class AgentIdentityService {
  AgentIdentityService({
    required IdentityService identityService,
    required MediatorAclService mediatorAclService,
    required DIDCommTransport didcommTransport,
    required ChannelRepository channelRepository,
    required Wallet wallet,
  }) : _identityService = identityService,
       _mediatorAclService = mediatorAclService,
       _didcommTransport = didcommTransport,
       _channelRepository = channelRepository,
       _wallet = wallet;

  final IdentityService _identityService;
  final MediatorAclService _mediatorAclService;
  final DIDCommTransport _didcommTransport;
  final ChannelRepository _channelRepository;
  final Wallet _wallet;

  /// Generates a fresh `did:web`, grants [otherPartyPermanentChannelDid]
  /// access on the mediator, sends back an
  /// `agent-create-channel-identity-response`, and persists a
  /// [ChannelStatus.approved] [Channel] linking the two permanent channel DIDs.
  ///
  /// Returns the new [Channel] so the caller can subscribe to messages on
  /// [Channel.permanentChannelDid].
  Future<Channel> createChannelIdentity({
    required String agentDid,
    required String otherPartyPermanentChannelDid,
    required String mediatorDid,
    required String offerLink,
    required String publishOfferDid,
    required ContactCard contactCard,
  }) async {
    final didManager = await _identityService.generateDidWeb(_wallet);
    final didDocument = await didManager.getDidDocument();
    final permanentChannelDid = didDocument.id;

    await _mediatorAclService.addToAcl(
      didManager: didManager,
      mediatorDid: mediatorDid,
      granteeDids: [otherPartyPermanentChannelDid],
    );

    final response = AgentCreateChannelIdentityResponse.create(
      from: agentDid,
      to: [otherPartyPermanentChannelDid],
      did: permanentChannelDid,
    );

    await _didcommTransport.sendMessage(
      response.toPlainTextMessage(),
      senderDid: agentDid,
      recipientDid: otherPartyPermanentChannelDid,
      mediatorDid: mediatorDid,
    );

    final channel = Channel(
      offerLink: offerLink,
      publishOfferDid: publishOfferDid,
      mediatorDid: mediatorDid,
      status: ChannelStatus.inaugurated,
      isConnectionInitiator: false,
      contactCard: contactCard,
      type: ChannelType.individual,
      transport: ChannelTransport.didcomm,
      permanentChannelDid: permanentChannelDid,
      otherPartyPermanentChannelDid: otherPartyPermanentChannelDid,
    );

    await _channelRepository.createChannel(channel);

    return channel;
  }
}
