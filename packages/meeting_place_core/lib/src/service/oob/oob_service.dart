import 'package:meeting_place_control_plane/meeting_place_control_plane.dart'
    hide ContactCard;
import 'package:meeting_place_mediator/meeting_place_mediator.dart';
import 'package:ssi/ssi.dart';

import '../../../meeting_place_core.dart';
import '../../event_handler/control_plane_event_stream_manager.dart';
import '../channel/channel_service.dart';
import '../../utils/attachment.dart';
import '../../utils/string.dart';
import '../connection_manager/connection_manager.dart';
import '../connection_service.dart';
import '../mediator/mediator_service.dart';
import 'session/oob_acceptance_session.dart';
import 'session/oob_offer_session.dart';

class OobService {
  OobService({
    required Wallet wallet,
    required MediatorService mediatorService,
    required ConnectionService connectionService,
    required ConnectionManager connectionManager,
    required ChannelService channelService,
    required ControlPlaneSDK controlPlaneSDK,
    required ControlPlaneEventStreamManager controlPlaneEventStreamManager,
    required MeetingPlaceMediatorSDK mediatorSDK,
    required MeetingPlaceCoreSDKLogger logger,
  }) : _wallet = wallet,
       _mediatorService = mediatorService,
       _connectionService = connectionService,
       _connectionManager = connectionManager,
       _channelService = channelService,
       _controlPlaneSDK = controlPlaneSDK,
       _controlPlaneEventStreamManager = controlPlaneEventStreamManager,
       _mediatorSDK = mediatorSDK,
       _logger = logger;

  final Wallet _wallet;
  final MediatorService _mediatorService;
  final ConnectionService _connectionService;
  final ConnectionManager _connectionManager;
  final ChannelService _channelService;
  final ControlPlaneSDK _controlPlaneSDK;
  final ControlPlaneEventStreamManager _controlPlaneEventStreamManager;
  final MeetingPlaceMediatorSDK _mediatorSDK;
  final MeetingPlaceCoreSDKLogger _logger;

  static final String _logKey = 'OobService';

  Future<OobOfferSession> createOobFlow({
    required ContactCard contactCard,
    required String mediatorDid,
    String? did,
    String? externalRef,
  }) async {
    _logger.info('Started creating OOB invitation', name: _logKey);

    // Create OOB data
    final oobDidManager = await _connectionManager.generateDid(_wallet);
    final oobDidDoc = await oobDidManager.getDidDocument();
    final oobMessage = OobInvitationMessage.create(from: oobDidDoc.id);

    _logger.info('''Setup OOB invitation for ${oobDidDoc.id.topAndTail()} on
      $mediatorDid''', name: _logKey);

    // Authenticate with the mediator before updating ACLs and
    // subscribing to messages. This ensures authentication occurs only once,
    // even though the following operations run in parallel.
    await _mediatorService.authenticate(
      didManager: oobDidManager,
      mediatorDid: mediatorDid,
    );

    final (_, oobCommandOutput, subscription) = await (
      _mediatorService.updateAcl(
        ownerDidManager: oobDidManager,
        mediatorDid: mediatorDid,
        acl: AclSet.toPublic(ownerDid: oobDidDoc.id),
      ),
      _controlPlaneSDK.execute(
        CreateOobCommand(
          oobInvitationMessage: oobMessage.toPlainTextMessage(),
          mediatorDid: mediatorDid,
        ),
      ),
      _mediatorService.subscribe(
        didManager: oobDidManager,
        mediatorDid: mediatorDid,
      ),
    ).wait;

    _logger.info(
      'OOB invitation created with URL: ${oobCommandOutput.oobUrl}',
      name: _logKey,
    );

    final session = OobOfferSession(
      didManager: oobDidManager,
      didDocument: oobDidDoc,
      oobInvitationMessage: oobMessage,
      oobUrl: Uri.parse(oobCommandOutput.oobUrl),
      contactCard: contactCard,
      mediatorDid: mediatorDid,
      subscription: subscription,
      logger: _logger,
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
        existingPermanentChannelDid: did,
        externalRef: externalRef,
      );

      return MediatorStreamProcessingResult(keepMessage: false);
    });

    _logger.info(
      ''''Listening for messages on mediator channel $mediatorDid and OOB DID
      ${oobDidDoc.id.topAndTail()}''',
      name: _logKey,
    );

    return session;
  }

  Future<OobAcceptanceSession> acceptOobFlow(
    Uri oobUrl, {
    required ContactCard contactCard,
    required String mediatorDid,
    String? externalRef,
    String? did,
    List<Attachment>? attachments,
  }) async {
    final methodName = 'acceptOobFlow';
    _logger.info('Started accepting OOB invitation', name: methodName);

    final acceptOfferDid = await _connectionManager.generateDid(_wallet);
    final acceptOfferDidDoc = await acceptOfferDid.getDidDocument();

    final permanentChannelDid = did != null
        ? await _connectionManager.getDidManagerForDid(_wallet, did)
        : await _connectionManager.generateDid(_wallet);

    final permanentChannelDidDoc = await permanentChannelDid.getDidDocument();

    PlainTextMessage invitationMessage;
    String actualMediatorDid;

    try {
      _logger.info('Fetching OOB invitation', name: methodName);
      final oobInfo = await _controlPlaneSDK.execute(
        GetOobCommand(oobId: oobUrl.pathSegments.last),
      );

      invitationMessage = OobInvitationMessage.fromBase64(
        oobInfo.invitationMessage,
      ).toPlainTextMessage();

      actualMediatorDid = oobInfo.mediatorDid;
    } catch (e, stackTrace) {
      _logger.error(
        '''Failed to fetch OOB invitation. Trying to fetch from mediator directly
        as fallback.''',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );
      invitationMessage = await _mediatorSDK.getOob(
        oobUrl,
        didManager: acceptOfferDid,
      );
      actualMediatorDid = '';
    }

    final channel = Channel(
      offerLink: invitationMessage.id,
      publishOfferDid: invitationMessage.from!,
      mediatorDid: actualMediatorDid,
      status: ChannelStatus.waitingForApproval,
      outboundMessageId: invitationMessage.id,
      acceptOfferDid: acceptOfferDidDoc.id,
      permanentChannelDid: permanentChannelDidDoc.id,
      type: ChannelType.oob,
      isConnectionInitiator: false,
      contactCard: contactCard,
      externalRef: externalRef,
    );

    final streamSubscription = await _mediatorService.subscribe(
      didManager: acceptOfferDid,
      mediatorDid: actualMediatorDid,
    );

    _logger.info(
      'Listening for messages on mediator channel',
      name: methodName,
    );

    final session = OobAcceptanceSession(
      channel: channel,
      permanentChannelDidManager: permanentChannelDid,
      permanentChannelDidDocument: permanentChannelDidDoc,
      subscription: streamSubscription,
      mediatorDid: actualMediatorDid,
      logger: _logger,
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
        existingPermanentChannelDid: did,
        externalRef: externalRef,
      );

      return MediatorStreamProcessingResult(keepMessage: false);
    });

    await _connectionService.sendAcceptOfferToMediator(
      acceptOfferDid: acceptOfferDid,
      permanentChannelDidDocument: permanentChannelDidDoc,
      invitationMessage: invitationMessage,
      mediatorDid: actualMediatorDid,
      acceptContactCard: contactCard,
      attachments: attachments,
    );

    await _channelService.persistChannel(channel);
    return session;
  }

  Future<void> _processInvitationAcceptance(
    InvitationAcceptance message, {
    required OobOfferSession session,
    String? existingPermanentChannelDid,
    String? externalRef,
  }) async {
    final otherPartyPermanentChannelDid = message.body.channelDid;
    final otherPartyCard = getContactCardDataOrEmptyFromAttachments(
      message.attachments,
    );

    final permanentChannelDidManager = existingPermanentChannelDid != null
        ? await _connectionManager.getDidManagerForDid(
            _wallet,
            existingPermanentChannelDid,
          )
        : await _connectionManager.generateDid(_wallet);

    final permanentChannelDidDoc = await permanentChannelDidManager
        .getDidDocument();

    await _connectionService.sendConnectionRequestApprovalToMediator(
      offerPublishedDid: session.didManager,
      permanentChannelDid: permanentChannelDidManager,
      otherPartyPermanentChannelDid: otherPartyPermanentChannelDid,
      otherPartyAcceptOfferDid: message.from,
      outboundMessageId: session.oobInvitationMessage.id,
      contactCard: session.contactCard,
      mediatorDid: session.mediatorDid,
    );

    final channel = Channel(
      offerLink: session.oobInvitationMessage.id,
      publishOfferDid: session.didDocument.id,
      mediatorDid: session.mediatorDid,
      outboundMessageId: session.oobInvitationMessage.id,
      acceptOfferDid: message.from,
      permanentChannelDid: permanentChannelDidDoc.id,
      otherPartyPermanentChannelDid: otherPartyPermanentChannelDid,
      status: ChannelStatus.inaugurated,
      type: ChannelType.oob,
      isConnectionInitiator: true,
      contactCard: session.contactCard,
      otherPartyContactCard: otherPartyCard,
      externalRef: externalRef,
    );

    await _channelService.persistChannel(channel);

    _logger.info(
      'OOB invitation accepted, channel created with ID: ${channel.id}',
      name: _logKey,
    );

    _controlPlaneEventStreamManager.pushEvent(
      ControlPlaneStreamEvent(
        channel: channel,
        type: ControlPlaneEventType.ChannelActivity,
      ),
    );

    session.stream.pushEvent(
      OobStreamData(
        eventType: EventType.connectionSetup,
        message: message.toPlainTextMessage(),
        channel: channel,
      ),
    );
  }

  _processConnectionRequestApproval(
    ConnectionRequestApproval message, {
    required OobAcceptanceSession session,
    String? existingPermanentChannelDid,
    String? externalRef,
    OnAttachmentsReceivedCallback? onAttachmentsReceived,
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

    final otherPartyCard = getContactCardDataOrEmptyFromAttachments(
      message.attachments,
    );

    await _channelService.markOobChannelInauguratedForNonConnectionInitiator(
      session.channel,
      outboundMessageId: message.parentThreadId,
      otherPartyPermanentChannelDid: otherPartyPermanentChannelDid,
      otherPartyCard: otherPartyCard,
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

    session.stream.pushEvent(
      OobStreamData(
        eventType: EventType.connectionAccepted,
        message: message.toPlainTextMessage(),
        channel: session.channel,
      ),
    );

    _logger.info(
      'OOB invitation accepted, channel created with ID: ${session.channel.id}',
      name: _logKey,
    );
  }
}
