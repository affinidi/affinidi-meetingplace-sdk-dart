import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:meeting_place_mediator/meeting_place_mediator.dart';
import 'package:ssi/ssi.dart';

import '../../../meeting_place_core.dart';
import '../../event_handler/control_plane_event_stream_manager.dart';
import '../../loggers/logger_adapter.dart';
import '../../messages/utils.dart';
import '../../sdk/results/accept_oob_flow_result.dart';
import '../../sdk/results/create_oob_flow_result.dart';
import '../connection_manager/connection_manager.dart';
import '../connection_service.dart';
import 'oob_stream.dart';

class OobService {
  OobService({
    required ConnectionManager connectionManager,
    required ConnectionService connectionService,
    required MeetingPlaceMediatorSDK mediatorSDK,
    required ControlPlaneSDK controlPlaneSDK,
    required ChannelRepository channelRepository,
    required ControlPlaneEventStreamManager controlPlaneEventStreamManager,
    required LoggerAdapter logger,
  })  : _connectionManager = connectionManager,
        _connectionService = connectionService,
        _mediatorSDK = mediatorSDK,
        _controlPlaneSDK = controlPlaneSDK,
        _channelRepository = channelRepository,
        _controlPlaneEventStreamManager = controlPlaneEventStreamManager,
        _logger = logger;

  final ControlPlaneSDK _controlPlaneSDK;
  final ConnectionManager _connectionManager;
  final ConnectionService _connectionService;
  final MeetingPlaceMediatorSDK _mediatorSDK;
  final LoggerAdapter _logger;
  final ChannelRepository _channelRepository;
  final ControlPlaneEventStreamManager _controlPlaneEventStreamManager;

  Future<CreateOobFlowResult> createOobFlow({
    required Wallet wallet,
    required String mediatorDid,
    required VCard vCard,
    String? did,
    String? externalRef,
  }) async {
    final methodName = 'createOobFlow';
    _logger.info('Started creating OOB invitation', name: methodName);

    final oobDidManager = await _connectionManager.generateDid(wallet);
    final oobDidDoc = await oobDidManager.getDidDocument();

    await _mediatorSDK.updateAcl(
      ownerDidManager: oobDidManager,
      mediatorDid: mediatorDid,
      acl: AclSet.toPublic(ownerDid: oobDidDoc.id),
    );

    final oobMessage = OobInvitationMessage.create(from: oobDidDoc.id);
    final result = await _controlPlaneSDK.execute(
      CreateOobCommand(oobInvitationMessage: oobMessage),
    );

    final streamSubscription = await _mediatorSDK
        .subscribeToMessages(oobDidManager, mediatorDid: result.mediatorDid);

    final oobStream = OobStream(
        onDispose: () => streamSubscription.dispose(), logger: _logger);
    _logger.info(
      'Listening for messages on mediator channel',
      name: methodName,
    );

    streamSubscription.listen((message) async {
      final plainTextMessage = message;

      if (plainTextMessage.type.toString() ==
          MeetingPlaceProtocol.connectionSetup.value) {
        final otherPartyVcard = getVCardDataOrEmptyFromAttachments(
          plainTextMessage.attachments,
        );

        final otherPartyPermanentChannelDid =
            plainTextMessage.body!['channel_did'];

        final permanentChannelDidManager = did != null
            ? await _connectionManager.getDidManagerForDid(
                wallet,
                did,
              )
            : await _connectionManager.generateDid(wallet);
        final permanentChannelDidDoc =
            await permanentChannelDidManager.getDidDocument();

        await _connectionService.sendConnectionRequestApprovalToMediator(
          offerPublishedDid: oobDidManager,
          permanentChannelDid: permanentChannelDidManager,
          otherPartyPermanentChannelDid: otherPartyPermanentChannelDid,
          otherPartyAcceptOfferDid: plainTextMessage.from!,
          outboundMessageId: oobMessage.id,
          vCard: vCard,
          mediatorDid: result.mediatorDid,
        );

        final channel = Channel(
          offerLink: oobMessage.id,
          publishOfferDid: oobDidDoc.id,
          mediatorDid: result.mediatorDid,
          outboundMessageId: oobMessage.id,
          acceptOfferDid: plainTextMessage.from!,
          permanentChannelDid: permanentChannelDidDoc.id,
          otherPartyPermanentChannelDid: otherPartyPermanentChannelDid,
          status: ChannelStatus.inaugurated,
          type: ChannelType.oob,
          vCard: vCard,
          otherPartyVCard: otherPartyVcard,
          externalRef: externalRef,
        );

        await _channelRepository.createChannel(channel);

        _logger.info(
          'OOB invitation accepted, channel created with ID: ${channel.id}',
          name: methodName,
        );

        _controlPlaneEventStreamManager.pushEvent(
          ControlPlaneStreamEvent(
            channel: channel,
            type: ControlPlaneEventType.ChannelActivity,
          ),
        );

        oobStream.pushEvent(
          OobStreamData(
            eventType: EventType.connectionSetup,
            message: plainTextMessage,
            channel: channel,
          ),
        );
      }
    });

    return CreateOobFlowResult(
      streamSubscription: oobStream,
      oobUrl: Uri.parse(result.oobUrl),
    );
  }

  Future<AcceptOobFlowResult> acceptOobFlow({
    required Wallet wallet,
    required String mediatorDid,
    required Uri oobUrl,
    required VCard vCard,
    String? externalRef,
  }) async {
    final methodName = 'acceptOobFlow';
    _logger.info('Started accepting OOB invitation', name: methodName);

    final acceptOfferDid = await _connectionManager.generateDid(wallet);
    final acceptOfferDidDoc = await acceptOfferDid.getDidDocument();

    final permanentChannelDid = await _connectionManager.generateDid(wallet);
    final didDoc = await permanentChannelDid.getDidDocument();

    PlainTextMessage invitationMessage;
    String actualMediatorDid = mediatorDid;

    try {
      _logger.info('Fetching OOB invitation', name: methodName);
      final oobInfo = await _controlPlaneSDK.execute(
        GetOobCommand(oobId: oobUrl.pathSegments.last),
      );

      invitationMessage = OobInvitationMessage.fromBase64(
        oobInfo.invitationMessage,
      );
      actualMediatorDid = oobInfo.mediatorDid;
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to fetch OOB invitation:',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );
      invitationMessage = await _mediatorSDK.getOob(
        oobUrl,
        didManager: acceptOfferDid,
      );
    }

    final channel = Channel(
      offerLink: invitationMessage.id,
      publishOfferDid: invitationMessage.from!,
      mediatorDid: actualMediatorDid,
      status: ChannelStatus.waitingForApproval,
      outboundMessageId: invitationMessage.id,
      acceptOfferDid: acceptOfferDidDoc.id,
      permanentChannelDid: didDoc.id,
      type: ChannelType.oob,
      vCard: vCard,
      externalRef: externalRef,
    );

    final streamSubscription = await _mediatorSDK
        .subscribeToMessages(acceptOfferDid, mediatorDid: actualMediatorDid);

    final oobStream = OobStream(
      onDispose: () => streamSubscription.dispose(),
      logger: _logger,
    );

    _logger.info(
      'Listening for messages on mediator channel',
      name: methodName,
    );

    streamSubscription.listen((message) async {
      if (message.type.toString() ==
              MeetingPlaceProtocol.connectionAccepted.value &&
          message.parentThreadId == invitationMessage.id) {
        final otherPartyPermanentChannelDid = message.body!['channel_did'];

        await _mediatorSDK.updateAcl(
          ownerDidManager: permanentChannelDid,
          acl: AccessListAdd(
            ownerDid: didDoc.id,
            granteeDids: [otherPartyPermanentChannelDid],
          ),
        );

        final otherPartyVCard = getVCardDataOrEmptyFromAttachments(
          message.attachments,
        );

        channel.otherPartyPermanentChannelDid = otherPartyPermanentChannelDid;
        channel.otherPartyVCard = otherPartyVCard;
        channel.status = ChannelStatus.inaugurated;

        await _channelRepository.updateChannel(channel);

        _controlPlaneEventStreamManager.pushEvent(
          ControlPlaneStreamEvent(
            channel: channel,
            type: ControlPlaneEventType.ChannelActivity,
          ),
        );

        oobStream.pushEvent(
          OobStreamData(
            eventType: EventType.connectionAccepted,
            message: message,
            channel: channel,
          ),
        );

        _logger.info(
          'OOB invitation accepted, channel created with ID: ${channel.id}',
          name: methodName,
        );
      }
    });

    await _connectionService.sendAcceptOfferToMediator(
      acceptOfferDid: acceptOfferDid,
      permanentChannelDidDocument: didDoc,
      invitationMessage: invitationMessage,
      mediatorDid: actualMediatorDid,
      acceptVCard: vCard,
    );

    await _channelRepository.createChannel(channel);
    return AcceptOobFlowResult(streamSubscription: oobStream, channel: channel);
  }
}
