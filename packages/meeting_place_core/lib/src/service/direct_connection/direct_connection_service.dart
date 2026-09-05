import 'package:didcomm/didcomm.dart';
import 'package:meeting_place_control_plane/meeting_place_control_plane.dart'
    hide ContactCard;
import 'package:meeting_place_mediator/meeting_place_mediator.dart';
import 'package:ssi/ssi.dart';

import '../../entity/entity.dart';
import '../../event_handler/control_plane_event_stream_manager.dart';
import '../../event_handler/control_plane_stream_event.dart';
import '../../loggers/meeting_place_core_sdk_logger.dart';
import '../../meeting_place_core_sdk_options.dart';
import '../../protocol/protocol.dart';
import '../../utils/string.dart';
import '../channel/channel_service.dart';
import '../connection_manager/connection_manager.dart';
import '../connection_service.dart';
import '../identity/identity_service.dart';
import '../mediator/mediator_service.dart';
import 'direct_connection_service_exception.dart';
import 'session/direct_connection_acceptance_session.dart';
import 'session/direct_connection_offer_session.dart';
import 'stream/direct_connection_stream.dart';
import 'stream/direct_connection_stream_data.dart';

class DirectConnectionService {
  DirectConnectionService({
    required Wallet wallet,
    required MediatorService mediatorService,
    required ConnectionService connectionService,
    required ConnectionManager connectionManager,
    required IdentityService identityService,
    required ChannelService channelService,
    required MeetingPlaceControlPlaneSDK controlPlaneSDK,
    required ControlPlaneEventStreamManager controlPlaneEventStreamManager,
    required MeetingPlaceCoreSDKLogger logger,
    void Function(Channel, List<Attachment>)? onAttachmentsReceived,
    OnBuildAttachmentsCallback? onBuildAttachments,
  }) : _wallet = wallet,
       _mediatorService = mediatorService,
       _connectionService = connectionService,
       _connectionManager = connectionManager,
       _identityService = identityService,
       _channelService = channelService,
       _controlPlaneEventStreamManager = controlPlaneEventStreamManager,
       _controlPlaneSDK = controlPlaneSDK,
       _onAttachmentsReceived = onAttachmentsReceived,
       _onBuildAttachments = onBuildAttachments,
       _logger = logger;

  final Wallet _wallet;
  final MediatorService _mediatorService;
  final ConnectionService _connectionService;
  final ConnectionManager _connectionManager;
  final IdentityService _identityService;
  final ChannelService _channelService;
  final ControlPlaneEventStreamManager _controlPlaneEventStreamManager;
  final MeetingPlaceControlPlaneSDK _controlPlaneSDK;
  final void Function(Channel, List<Attachment>)? _onAttachmentsReceived;
  final OnBuildAttachmentsCallback? _onBuildAttachments;
  final MeetingPlaceCoreSDKLogger _logger;

  static final String _logKey = 'DirectConnectionService';

  Future<DirectConnectionOfferSession> createDirectConnection({
    required ContactCard contactCard,
    required String mediatorDid,
    String? type,
    String? did,
    String? externalRef,
  }) async {
    _logger.info(
      'Started creating direct connection invitation',
      name: _logKey,
    );

    // Create direct connection data
    final offerIdentity = await _identityService.createEphemeralIdentity(
      _wallet,
    );
    final invitationMessage = OobInvitationMessage.create(
      from: offerIdentity.didDocument.id,
      type: type,
    );

    _logger.info(
      '''Setup direct connection invitation for
      ${offerIdentity.didDocument.id.topAndTail()} on $mediatorDid''',
      name: _logKey,
    );

    // Authenticate with the mediator before updating ACLs and
    // subscribing to messages. This ensures authentication occurs only once,
    // even though the following operations run in parallel.
    await _mediatorService.authenticate(
      didManager: offerIdentity.didManager,
      mediatorDid: mediatorDid,
    );

    final (_, oobOutput, subscription) = await (
      _mediatorService.updateAcl(
        ownerDidManager: offerIdentity.didManager,
        mediatorDid: mediatorDid,
        acl: AccessListSet.toPublic(ownerDid: offerIdentity.didDocument.id),
      ),
      _controlPlaneSDK.execute(
        CreateOobCommand(
          oobInvitationMessage: invitationMessage.toPlainTextMessage(),
          mediatorDid: mediatorDid,
        ),
      ),
      _mediatorService.subscribe(
        didManager: offerIdentity.didManager,
        mediatorDid: mediatorDid,
      ),
    ).wait;

    _logger.info(
      'Direct connection invitation created with URL: ${oobOutput.oobUrl}',
      name: _logKey,
    );

    final directConnectionStream = DirectConnectionStream(
      onDispose: subscription.dispose,
      logger: _logger,
    );

    final session = DirectConnectionOfferSession(
      didManager: offerIdentity.didManager,
      didDocument: offerIdentity.didDocument,
      oobInvitationMessage: invitationMessage,
      directConnectionUrl: Uri.parse(oobOutput.oobUrl),
      contactCard: contactCard,
      mediatorDid: mediatorDid,
      stream: directConnectionStream,
    );

    subscription.listen((mediatorMessage) async {
      final plainTextMessage = mediatorMessage.plainTextMessage;

      if (plainTextMessage.type.toString() !=
          MeetingPlaceProtocol.invitationAcceptance.value) {
        return MediatorStreamProcessingResult(keepMessage: true);
      }

      final message = InvitationAcceptance.fromPlainTextMessage(
        plainTextMessage,
      );

      await _processInvitationAcceptance(
        message,
        session: session,
        stream: directConnectionStream,
        existingPermanentChannelDid: did,
        externalRef: externalRef,
        onAttachmentsReceived: _onAttachmentsReceived,
      );

      return MediatorStreamProcessingResult(keepMessage: false);
    });

    _logger.info(
      '''Listening for messages on mediator channel $mediatorDid and direct
      connection DID ${offerIdentity.didDocument.id.topAndTail()}''',
      name: _logKey,
    );

    return session;
  }

  Future<DirectConnectionAcceptanceSession> acceptDirectConnection(
    Uri directConnectionUri, {
    required ContactCard contactCard,
    required String mediatorDid,
    String? type,
    String? externalRef,
    String? did,
    List<Attachment>? attachments,
  }) async {
    _logger.info(
      'Started accepting direct connection invitation',
      name: _logKey,
    );

    final acceptOfferIdentity = await _identityService.createEphemeralIdentity(
      _wallet,
    );

    final permanentIdentity = did != null
        ? await _identityService.getPermanentIdentity(_wallet, did)
        : await _identityService.createPermanentIdentity(_wallet);

    final (invitationMessage, mediatorDid) = await _fetchInvitation(
      directConnectionUri: directConnectionUri,
      type: type,
    );

    final channel = Channel(
      offerLink: invitationMessage.id,
      publishOfferDid: invitationMessage.from,
      mediatorDid: mediatorDid,
      status: ChannelStatus.waitingForApproval,
      outboundMessageId: invitationMessage.id,
      acceptOfferDid: acceptOfferIdentity.didDocument.id,
      permanentChannelDid: permanentIdentity.didDocument.id,
      type: ChannelType.directConnection,
      isConnectionInitiator: false,
      contactCard: contactCard,
      externalRef: externalRef,
      transport: ChannelTransport.didcomm,
    );

    final streamSubscription = await _mediatorService.subscribe(
      didManager: acceptOfferIdentity.didManager,
      mediatorDid: mediatorDid,
    );

    final directConnectionStream = DirectConnectionStream(
      onDispose: streamSubscription.dispose,
      logger: _logger,
    );

    final session = DirectConnectionAcceptanceSession(
      channel: channel,
      permanentChannelDidManager: permanentIdentity.didManager,
      permanentChannelDidDocument: permanentIdentity.didDocument,
      stream: directConnectionStream,
      mediatorDid: mediatorDid,
    );

    _logger.info(
      'Listening for messages on mediator $mediatorDid',
      name: _logKey,
    );

    streamSubscription.listen((mediatorMessage) async {
      final plainTextMessage = mediatorMessage.plainTextMessage;

      if (plainTextMessage.type.toString() !=
              MeetingPlaceProtocol.connectionRequestApproval.value ||
          plainTextMessage.parentThreadId != invitationMessage.id) {
        return MediatorStreamProcessingResult(keepMessage: true);
      }

      final message = ConnectionRequestApproval.fromPlainTextMessage(
        plainTextMessage,
      );

      await _processConnectionRequestApproval(
        message,
        session: session,
        stream: directConnectionStream,
        existingPermanentChannelDid: did,
        externalRef: externalRef,
        onAttachmentsReceived: _onAttachmentsReceived,
      );

      return MediatorStreamProcessingResult(keepMessage: false);
    });

    final builtAttachments = await _onBuildAttachments?.call(
      channel,
      (did) => _connectionManager.getDidManagerForDid(_wallet, did),
    );
    final mergedAttachments = [...?attachments, ...?builtAttachments];

    await _connectionService.sendAcceptOfferToMediator(
      acceptOfferDidManager: acceptOfferIdentity.didManager,
      permanentChannelDidDocument: permanentIdentity.didDocument,
      invitationMessage: invitationMessage.toPlainTextMessage(),
      mediatorDid: mediatorDid,
      acceptContactCard: contactCard,
      attachments: mergedAttachments.isEmpty ? null : mergedAttachments,
    );

    await _channelService.persistChannel(channel);
    return session;
  }

  Future<void> _processInvitationAcceptance(
    InvitationAcceptance message, {
    required DirectConnectionOfferSession session,
    required DirectConnectionStream stream,
    String? existingPermanentChannelDid,
    String? externalRef,
    void Function(Channel, List<Attachment>)? onAttachmentsReceived,
  }) async {
    final otherPartyPermanentChannelDid = message.body.channelDid;

    final permanentChannelDidManager = existingPermanentChannelDid != null
        ? await _connectionManager.getDidManagerForDid(
            _wallet,
            existingPermanentChannelDid,
          )
        : (await _identityService.createPermanentIdentity(_wallet)).didManager;

    final permanentChannelDidDoc = await permanentChannelDidManager
        .getDidDocument();

    final channel = Channel(
      offerLink: session.oobInvitationMessage.id,
      publishOfferDid: session.didDocument.id,
      mediatorDid: session.mediatorDid,
      outboundMessageId: session.oobInvitationMessage.id,
      acceptOfferDid: message.from,
      permanentChannelDid: permanentChannelDidDoc.id,
      otherPartyPermanentChannelDid: otherPartyPermanentChannelDid,
      status: ChannelStatus.inaugurated,
      type: ChannelType.directConnection,
      isConnectionInitiator: true,
      contactCard: session.contactCard,
      otherPartyContactCard: message.contactCard,
      externalRef: externalRef,
      transport: ChannelTransport.didcomm,
    );

    final outgoingAttachments = await _onBuildAttachments?.call(
      channel,
      (did) => _connectionManager.getDidManagerForDid(_wallet, did),
    );

    await _connectionService.sendConnectionRequestApprovalToMediator(
      offerPublishedDidManager: session.didManager,
      permanentChannelDidManager: permanentChannelDidManager,
      otherPartyPermanentChannelDid: otherPartyPermanentChannelDid,
      otherPartyAcceptOfferDid: message.from,
      outboundMessageId: session.oobInvitationMessage.id,
      contactCard: session.contactCard,
      mediatorDid: session.mediatorDid,
      attachments: outgoingAttachments,
    );

    await _channelService.persistChannel(channel);

    _logger.info(
      'Direct connection invitation accepted, channel created with ID: '
      '${channel.id}',
      name: _logKey,
    );

    _controlPlaneEventStreamManager.pushEvent(
      ControlPlaneStreamEvent(
        channel: channel,
        type: ControlPlaneEventType.ChannelActivity,
      ),
    );

    final attachments = message.attachments;
    if (attachments != null && attachments.isNotEmpty) {
      onAttachmentsReceived?.call(channel, attachments);
    }

    stream.pushEvent(
      DirectConnectionStreamData(
        eventType: EventType.connectionSetup,
        message: message.toPlainTextMessage(),
        channel: channel,
      ),
    );
  }

  Future<void> _processConnectionRequestApproval(
    ConnectionRequestApproval message, {
    required DirectConnectionAcceptanceSession session,
    required DirectConnectionStream stream,
    String? existingPermanentChannelDid,
    String? externalRef,
    void Function(Channel, List<Attachment>)? onAttachmentsReceived,
  }) async {
    final otherPartyPermanentChannelDid = message.body.channelDid;

    await _mediatorService.updateAcl(
      ownerDidManager: session.permanentChannelDidManager,
      mediatorDid: session.mediatorDid,
      acl: AccessListAdd(
        ownerDid: session.permanentChannelDidDocument.id,
        granteeDids: [otherPartyPermanentChannelDid],
      ),
    );

    await _channelService
        .markDirectConnectionChannelInauguratedForNonConnectionInitiator(
          session.channel,
          outboundMessageId: message.parentThreadId,
          otherPartyPermanentChannelDid: otherPartyPermanentChannelDid,
          otherPartyContactCard: message.contactCard,
        );

    final attachments = message.attachments;
    if (attachments != null && attachments.isNotEmpty) {
      onAttachmentsReceived?.call(session.channel, attachments);
    }

    _controlPlaneEventStreamManager.pushEvent(
      ControlPlaneStreamEvent(
        channel: session.channel,
        type: ControlPlaneEventType.ChannelActivity,
      ),
    );

    stream.pushEvent(
      DirectConnectionStreamData(
        eventType: EventType.connectionAccepted,
        message: message.toPlainTextMessage(),
        channel: session.channel,
      ),
    );

    _logger.info(
      'Direct connection invitation accepted, channel created with ID: '
      '${session.channel.id}',
      name: _logKey,
    );
  }

  Future<(OobInvitationMessage, String)> _fetchInvitation({
    required Uri directConnectionUri,
    String? type,
  }) async {
    _logger.info(
      'Fetching direct connection invitation via HTTP GET',
      name: _logKey,
    );

    try {
      // TODO: handle errors here
      final oobId = directConnectionUri.pathSegments.last;
      final oob = await _controlPlaneSDK.execute(GetOobCommand(oobId: oobId));

      final invitationMessage = OobInvitationMessage.fromBase64(
        oob.invitationMessage,
      );

      _validateInvitation(invitationMessage, directConnectionUri, type);
      return (invitationMessage, oob.mediatorDid);
    } on MeetingPlaceControlPlaneSDKException catch (e) {
      if (e.code == MeetingPlaceControlPlaneSDKErrorCode.oobNotFound.value) {
        throw DirectConnectionServiceException.notFound(
          directConnectionUri: directConnectionUri,
          innerException: e,
        );
      }

      if (e.code == MeetingPlaceControlPlaneSDKErrorCode.networkError.value) {
        throw DirectConnectionServiceException.networkError(
          directConnectionUri: directConnectionUri,
          innerException: e,
        );
      }

      throw DirectConnectionServiceException.invalidResponse(innerException: e);
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to fetch direct connection invitation from '
        '$directConnectionUri, error: $e',
        name: _logKey,
        stackTrace: stackTrace,
      );

      if (e is DirectConnectionServiceException) {
        rethrow;
      }

      Error.throwWithStackTrace(
        DirectConnectionServiceException.generic(
          directConnectionUri: directConnectionUri,
        ),
        stackTrace,
      );
    }
  }

  void _validateInvitation(
    OobInvitationMessage invitationMessage,
    Uri directConnectionUri,
    String? type,
  ) {
    if (type != null && invitationMessage.body.goalCode != type) {
      _logger.error('''Direct connection invitation type
        ${invitationMessage.body.goalCode} does not match expected type
        $type''', name: _logKey);

      throw DirectConnectionServiceException.invalidType(
        directConnectionUri: directConnectionUri,
        expectedType: type,
        actualType: invitationMessage.body.goalCode,
      );
    }
  }
}
