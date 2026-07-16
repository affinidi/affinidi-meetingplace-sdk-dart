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
    required Wallet wallet,
    required ConnectionManager connectionManager,
    required MatrixService matrixService,
  }) : _identityService = identityService,
       _mediatorAclService = mediatorAclService,
       _didcommTransport = didcommTransport,
       _channelRepository = channelRepository,
       _wallet = wallet,
       _connectionManager = connectionManager,
       _matrixService = matrixService;

  final IdentityService _identityService;
  final MediatorAclService _mediatorAclService;
  final DIDCommTransport _didcommTransport;
  final ChannelRepository _channelRepository;
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
  Future<void> createChannelIdentity({
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

    final channel = Channel(
      offerLink: offerLink,
      publishOfferDid: publishOfferDid,
      mediatorDid: mediatorDid,
      status: ChannelStatus.waitingForApproval,
      isConnectionInitiator: false,
      contactCard: contactCard,
      type: ChannelType.individual,
      transport: transport,
      permanentChannelDid: permanentChannelDid,
    );

    await _channelRepository.createChannel(channel);
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
