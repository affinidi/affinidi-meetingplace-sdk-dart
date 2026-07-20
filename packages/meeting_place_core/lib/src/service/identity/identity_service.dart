import 'dart:async';

import 'package:ssi/ssi.dart';

import '../../../meeting_place_core.dart';
import '../../protocol/message/agent_create_channel_identity_request/agent_create_channel_identity_request.dart';
import '../connection_manager/connection_manager.dart';
import '../mediator/mediator_service.dart';
import '../message/message_service.dart';
import 'did_web_document_service.dart';
import 'model/ephemeral_identity.dart';
import 'model/permanent_identity.dart';

class IdentityService {
  IdentityService({
    required ConnectionManager connectionManager,
    required MatrixService matrixService,
    required DidWebDocumentService didWebDocumentService,
    required Uri didWebBaseHost,
    required MessageService messageService,
    required MediatorService mediatorService,
    required String mediatorDid,
    this.agentDid,
    MeetingPlaceCoreSDKLogger? logger,
  }) : _connectionManager = connectionManager,
       _matrixService = matrixService,
       _didWebDocumentService = didWebDocumentService,
       _didWebBaseHost = didWebBaseHost,
       _messageService = messageService,
       _mediatorService = mediatorService,
       _mediatorDid = mediatorDid,
       _logger =
           logger ?? DefaultMeetingPlaceCoreSDKLogger(className: _className);

  final ConnectionManager _connectionManager;
  final MatrixService _matrixService;
  final DidWebDocumentService _didWebDocumentService;
  final Uri _didWebBaseHost;
  final MessageService _messageService;
  final MediatorService _mediatorService;
  final String _mediatorDid;
  final MeetingPlaceCoreSDKLogger _logger;

  /// DID of the personal AI agent. When non-null, a channel identity
  /// handshake is performed on every [createPermanentIdentity] call.
  final String? agentDid;

  static const String _className = 'IdentityService';
  static const String _logkey = 'IdentityService';

  Future<DidManager> generateDidWeb(Wallet wallet) async {
    final didManager = await _connectionManager.generateDidWeb(
      wallet,
      baseHost: _didWebBaseHost,
    );
    final didDocument = await didManager.getDidDocument();
    await _didWebDocumentService.register(
      didManager: didManager,
      didDocument: didDocument,
    );
    return didManager;
  }

  Future<EphemeralIdentity> createEphemeralIdentity(Wallet wallet) async {
    final ephemeralDidManager = await _connectionManager.generateEphemeralDid(
      wallet,
    );
    final didDocument = await ephemeralDidManager.getDidDocument();

    _logger.info(
      'Created ephemeral identity with DID ${didDocument.id}',
      name: _logkey,
    );

    return EphemeralIdentity(
      didManager: ephemeralDidManager,
      didDocument: didDocument,
    );
  }

  Future<PermanentIdentity> createPermanentIdentity(
    Wallet wallet, {
    required ChannelTransport transport,
    String? offerLink,
    String? publishOfferDid,
    ContactCard? contactCard,
    bool? skipAgentIdentity = false,
  }) async {
    final permanentChannelDidManager = await _connectionManager.generateDidWeb(
      wallet,
      baseHost: _didWebBaseHost,
    );

    final didDocument = await permanentChannelDidManager.getDidDocument();

    await _didWebDocumentService.register(
      didManager: permanentChannelDidManager,
      didDocument: didDocument,
    );

    String? matrixUserId;
    if (transport == ChannelTransport.matrix) {
      matrixUserId = await _matrixService.loginWithDid(
        permanentChannelDidManager,
      );
    }

    String? personalAgentPermanentChannelDid;
    if (skipAgentIdentity == false && agentDid != null) {
      personalAgentPermanentChannelDid = await _requestAgentChannelIdentity(
        wallet: wallet,
        senderDidManager: permanentChannelDidManager,
        channelDid: didDocument.id,
        agentDid: agentDid!,
        transport: transport,
        offerLink: offerLink,
        publishOfferDid: publishOfferDid,
        contactCard: contactCard,
      );
    }

    _logger.info(
      'Created permanent identity with DID ${didDocument.id}, '
      'Matrix user ID $matrixUserId, '
      'agent DID $personalAgentPermanentChannelDid',
      name: _logkey,
    );

    return PermanentIdentity(
      didManager: permanentChannelDidManager,
      didDocument: didDocument,
      matrixUserId: matrixUserId,
      agentDid: personalAgentPermanentChannelDid,
    );
  }

  Future<PermanentIdentity> getPermanentIdentity(
    Wallet wallet,
    String did,
  ) async {
    final permanentChannelDidManager = await _connectionManager
        .getDidManagerForDid(wallet, did);

    final matrixUserId = await _matrixService.loginWithDid(
      permanentChannelDidManager,
    );

    _logger.info(
      '''Restored permanent identity with DID $did and Matrix user ID $matrixUserId''',
      name: _logkey,
    );

    final didDocument = await permanentChannelDidManager.getDidDocument();

    return PermanentIdentity(
      didManager: permanentChannelDidManager,
      didDocument: didDocument,
      matrixUserId: matrixUserId,
    );
  }

  Future<String> _requestAgentChannelIdentity({
    required Wallet wallet,
    required DidManager senderDidManager,
    required String channelDid,
    required String agentDid,
    required ChannelTransport transport,
    String? offerLink,
    String? publishOfferDid,
    ContactCard? contactCard,
  }) async {
    await _mediatorService.updateAcl(
      ownerDidManager: senderDidManager,
      mediatorDid: _mediatorDid,
      acl: AccessListAdd(ownerDid: channelDid, granteeDids: [agentDid]),
    );

    final subscription = await _mediatorService.subscribe(
      didManager: senderDidManager,
      mediatorDid: _mediatorDid,
    );

    if (offerLink == null || publishOfferDid == null || contactCard == null) {
      _logger.warning(
        '''Requesting agent channel identity without offerLink, publishOfferDid, or contactCard''',
        name: _logkey,
      );
    }

    try {
      final rootDidManager = await _connectionManager.generateRootDid(wallet);
      final rootDidDoc = await rootDidManager.getDidDocument();
      final request = AgentCreateChannelIdentityRequest.create(
        from: rootDidDoc.id,
        to: [agentDid],
        channelDid: channelDid,
        offerLink: offerLink!,
        publishOfferDid: publishOfferDid!,
        contactCard: contactCard!,
        transport: transport,
      );

      await _messageService.sendMessage(
        request.toPlainTextMessage(),
        senderDidManager: rootDidManager,
        recipientDid: agentDid,
        mediatorDid: _mediatorDid,
      );

      _logger.info(
        'Sent agent channel identity request for DID $channelDid',
        name: _logkey,
      );

      final response = await subscription.stream
          .where(
            (m) =>
                m.plainTextMessage.type.toString() ==
                MeetingPlaceProtocol.agentCreateChannelIdentityResponse.value,
          )
          .first
          .timeout(const Duration(seconds: 30));

      final agentPermanentChannelDid =
          response.plainTextMessage.body!['did'] as String;

      _logger.info(
        '''Received agent channel identity DID $agentPermanentChannelDid for channel $channelDid''',
        name: _logkey,
      );

      await subscription.dispose();
      return agentPermanentChannelDid;
    } finally {
      await subscription.dispose();
    }
  }
}
