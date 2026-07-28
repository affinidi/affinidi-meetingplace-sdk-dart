import 'package:ssi/ssi.dart';

import '../../meeting_place_core.dart';
import '../protocol/message/agent_create_channel_identity_response/agent_create_channel_identity_response.dart';
import 'connection_manager/connection_manager.dart';
import 'identity/identity_service.dart';
import 'mediator/mediator_acl_service.dart';

class AgentIdentityService {
  AgentIdentityService({
    required IdentityService identityService,
    required MediatorAclService mediatorAclService,
    required DIDCommTransport didcommTransport,
    required ChannelRepository channelRepository,
    required ConnectionOfferRepository connectionOfferRepository,
    required GroupRepository groupRepository,
    required Wallet wallet,
    required ConnectionManager connectionManager,
    required MatrixService matrixService,
  }) : _identityService = identityService,
       _mediatorAclService = mediatorAclService,
       _didcommTransport = didcommTransport,
       _channelRepository = channelRepository,
       _connectionOfferRepository = connectionOfferRepository,
       _groupRepository = groupRepository,
       _wallet = wallet,
       _connectionManager = connectionManager,
       _matrixService = matrixService;

  final IdentityService _identityService;
  final MediatorAclService _mediatorAclService;
  final DIDCommTransport _didcommTransport;
  final ChannelRepository _channelRepository;
  final ConnectionOfferRepository _connectionOfferRepository;
  final GroupRepository _groupRepository;
  final Wallet _wallet;
  final ConnectionManager _connectionManager;
  final MatrixService _matrixService;

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
    required ChannelTransport transport,
    required String agentControllerDid,
  }) async {
    final didManager = await _identityService.generateDidWeb(_wallet);
    final didDocument = await didManager.getDidDocument();
    final permanentChannelDid = didDocument.id;

    await _mediatorAclService.addToAcl(
      didManager: didManager,
      mediatorDid: mediatorDid,
      granteeDids: [otherPartyPermanentChannelDid, agentControllerDid],
    );

    final agentDidManager = await _connectionManager.getDidManagerForDid(
      _wallet,
      agentDid,
    );
    await _mediatorAclService.addToAcl(
      didManager: agentDidManager,
      mediatorDid: mediatorDid,
      granteeDids: [otherPartyPermanentChannelDid],
    );

    if (transport == ChannelTransport.matrix) {
      await _matrixService.loginWithDid(didManager);
    }

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

    final channelType = await _deriveChannelType(
      offerLink: offerLink,
      transport: transport,
    );

    final channel = Channel(
      offerLink: offerLink,
      publishOfferDid: publishOfferDid,
      mediatorDid: mediatorDid,
      status: ChannelStatus.waitingForApproval,
      isConnectionInitiator: false,
      contactCard: contactCard,
      type: channelType,
      transport: transport,
      permanentChannelDid: permanentChannelDid,
    );

    await _channelRepository.createChannel(channel);
    return channel;
  }

  Future<ChannelType> _deriveChannelType({
    required String offerLink,
    required ChannelTransport transport,
  }) async {
    if (transport != ChannelTransport.matrix) {
      return ChannelType.individual;
    }

    final connectionOffer = await _connectionOfferRepository
        .getConnectionOfferByOfferLink(offerLink);
    if (connectionOffer is GroupConnectionOffer) {
      return ChannelType.group;
    }

    final group = await _groupRepository.getGroupByOfferLink(offerLink);
    return group == null ? ChannelType.individual : ChannelType.group;
  }

  /// Handles an incoming `agent-channel-inauguration` message by granting
  /// [otherPartyPermanentChannelDid] access on the mediator, persisting a
  /// [ChannelStatus.inaugurated] [Channel], and returning it so the caller
  /// can open a chat session on [Channel.permanentChannelDid].
  Future<Channel> processAgentChannelInauguration({
    required String otherPartyPermanentChannelDid,
    required String otherPartyNotificationToken,
    required String agentPermanentChannelDid,
    ContactCard? contactCard,
    String? matrixRoomId,
  }) async {
    final channel = await _channelRepository.findChannelByDid(
      agentPermanentChannelDid,
    );

    if (channel == null) {
      throw Exception(
        '''Channel not found for otherPartyPermanentChannelDid: $otherPartyPermanentChannelDid''',
      );
    }

    final didManager = await _connectionManager.getDidManagerForDid(
      _wallet,
      agentPermanentChannelDid,
    );

    await _mediatorAclService.addToAcl(
      didManager: didManager,
      mediatorDid: channel.mediatorDid,
      granteeDids: [otherPartyPermanentChannelDid],
    );

    if (channel.transport == ChannelTransport.matrix && matrixRoomId != null) {
      await _matrixService.joinRoomById(
        didManager: didManager,
        roomId: matrixRoomId,
      );
    }

    // TODO(SR): ContactCard required?
    channel.status = ChannelStatus.inaugurated;
    channel.otherPartyPermanentChannelDid = otherPartyPermanentChannelDid;
    channel.otherPartyNotificationToken = otherPartyNotificationToken;
    channel.matrixRoomId = matrixRoomId;

    await _channelRepository.updateChannel(channel);
    return channel;
  }
}
