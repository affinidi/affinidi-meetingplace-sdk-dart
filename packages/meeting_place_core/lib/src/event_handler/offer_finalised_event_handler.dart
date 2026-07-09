import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:ssi/ssi.dart';

import '../../meeting_place_core.dart';
import '../protocol/protocol.dart' as protocol;
import '../service/identity/identity_service.dart';
import '../service/mediator/fetch_messages_options.dart';
import '../utils/string.dart';
import 'base_event_handler.dart';

class OfferFinalisedEventHandler extends BaseEventHandler<OfferFinalised> {
  OfferFinalisedEventHandler({
    required super.wallet,
    required super.connectionOfferRepository,
    required super.channelService,
    required super.connectionManager,
    required super.mediatorService,
    required super.logger,
    required super.options,
    required ControlPlaneSDK controlPlaneSDK,
    required DidResolver didResolver,
    required MatrixService matrixService,
    required IdentityService identityService,
  }) : _controlPlaneSDK = controlPlaneSDK,
       _didResolver = didResolver,
       _matrixService = matrixService,
       _identityService = identityService;

  final ControlPlaneSDK _controlPlaneSDK;
  final DidResolver _didResolver;
  final MatrixService _matrixService;
  final IdentityService _identityService;

  Future<List<Channel>> process(OfferFinalised event) async {
    logger.info(
      'Started processing OfferFinalised event for offerLink: '
      '${event.offerLink}',
      name: 'process',
    );

    final connection = await findConnectionByOfferLink(event.offerLink);
    if (connection.isFinalised) {
      throw Exception(
        'Connection offer ${connection.offerLink} already finalised',
      );
    }

    final permanentChannelDid = connection.permanentChannelDid;
    if (permanentChannelDid == null) {
      throw Exception('''Connection offer ${connection.offerLink} is missing
        permanentChannelDid''');
    }

    final channel = await channelService.findChannelByDid(permanentChannelDid);

    final acceptOfferDid = connection.acceptOfferDid;
    if (acceptOfferDid == null) {
      throw Exception(
        'Connection offer ${connection.offerLink} is missing acceptOfferDid',
      );
    }

    final acceptOfferDidManager = await connectionManager.getDidManagerForDid(
      wallet,
      acceptOfferDid,
    );

    return processEvent(
      event: event,
      didManager: acceptOfferDidManager,
      mediatorDid: connection.mediatorDid,
      connection: connection,
      channel: channel,
      fetchMessageOptions: FetchMessagesOptions(
        filterByMessageTypes: [
          MeetingPlaceProtocol.connectionRequestApproval.value,
        ],
      ),
    );
  }

  @override
  Future<Channel> processMessage(
    PlainTextMessage message, {
    required OfferFinalised event,
    ConnectionOffer? connection,
    Channel? channel,
  }) async {
    if (connection == null) {
      throw ArgumentError('''Connection offer must be provided to process
        ConnectionRequestApproval message''');
    }

    if (channel == null) {
      throw ArgumentError('''Channel must be provided to process
        ConnectionRequestApproval message''');
    }

    final messageFrom = message.from;
    if (messageFrom == null) {
      throw ArgumentError('''Message must have a sender (from) to process
        ConnectionRequestApproval message''');
    }

    final acceptOfferDid = channel.acceptOfferDid;
    final permanentChannelDid = channel.permanentChannelDid;

    if (acceptOfferDid == null || permanentChannelDid == null) {
      throw ArgumentError('''Channel must have acceptOfferDid and
        permanentChannelDid to process ConnectionRequestApproval message''');
    }

    final acceptOfferDidManager = await connectionManager.getDidManagerForDid(
      wallet,
      acceptOfferDid,
    );

    final permanentChannelIdentity = await _identityService
        .getPermanentIdentity(wallet, permanentChannelDid);

    final connectionRequestApprovalMessage =
        protocol.ConnectionRequestApproval.fromPlainTextMessage(message);

    final otherPartyPermanentChannelDid =
        connectionRequestApprovalMessage.body.channelDid;

    logger.info('''Found ConnectionRequestApproval. Their channel
      is $otherPartyPermanentChannelDid''', name: 'processMessage');

    final notificationToken = await _registerNotificationToken(
      permanentChannelIdentity.didDocument.id,
      otherPartyPermanentChannelDid,
    );

    if (channel.transport == ChannelTransport.matrix) {
      await _matrixService.joinChannelRoom(
        didManager: permanentChannelIdentity.didManager,
        channelDid: permanentChannelIdentity.didDocument.id,
        otherPartyChannelDid: otherPartyPermanentChannelDid,
      );
    }

    await _updateMediatorAcls(
      permanentChannelDidManager: permanentChannelIdentity.didManager,
      permanentChannelDid: permanentChannelIdentity.didDocument.id,
      acceptOfferDidManager: acceptOfferDidManager,
      acceptOfferDid: acceptOfferDid,
      otherPartyPermanentChannelDid: otherPartyPermanentChannelDid,
      messageFrom: messageFrom,
      mediatorDid: channel.mediatorDid,
    );

    final agentPermanentChannelDid = channel.agentPermanentChannelDid;
    if (agentPermanentChannelDid != null) {
      await _sendAgentChannelInaugurationMessage(
        channel: channel,
        permanentChannelDidManager: permanentChannelIdentity.didManager,
        permanentChannelDid: permanentChannelIdentity.didDocument.id,
        agentPermanentChannelDid: agentPermanentChannelDid,
        otherPartyPermanentChannelDid: otherPartyPermanentChannelDid,
        otherPartyNotificationToken: event.notificationToken,
      );
    }

    await _sendChannelInaugurationMessage(
      channel: channel,
      permanentChannelDidManager: permanentChannelIdentity.didManager,
      permanentChannelDid: permanentChannelIdentity.didDocument.id,
      otherPartyPermanentChannelDid: otherPartyPermanentChannelDid,
      notificationToken: notificationToken,
    );

    await channelService.markChannelInauguratedForNonConnectionInitiator(
      channel,
      notificationToken: notificationToken,
      otherPartyNotificationToken: event.notificationToken,
      otherPartyPermanentChannelDid: otherPartyPermanentChannelDid,
      outboundMessageId: message.id,
      otherPartyContactCard: connectionRequestApprovalMessage.contactCard,
    );

    final attachments = message.attachments;
    if (attachments != null && attachments.isNotEmpty) {
      options.onAttachmentsReceived?.call(channel, attachments);
    }

    final approvedConnection = connection.finalised(
      outboundMessageId: message.id,
      otherPartyPermanentChannelDid: otherPartyPermanentChannelDid,
      notificationToken: notificationToken,
      otherPartyNotificationToken: event.notificationToken,
    );

    await connectionOfferRepository.updateConnectionOffer(approvedConnection);

    await _notifyChannel(
      notificationToken: event.notificationToken,
      did: otherPartyPermanentChannelDid,
    );

    return channel;
  }

  Future<void> _sendChannelInaugurationMessage({
    required Channel channel,
    required DidManager permanentChannelDidManager,
    required String permanentChannelDid,
    required String otherPartyPermanentChannelDid,
    required String notificationToken,
  }) async {
    final otherPartyPermanentChannelDidDocument = await _didResolver.resolveDid(
      otherPartyPermanentChannelDid,
    );

    var outgoingAttachments = await options.onBuildAttachments?.call(
      channel,
      (did) => connectionManager.getDidManagerForDid(wallet, did),
    );

    return mediatorService.sendMessage(
      ChannelInauguration.create(
        from: permanentChannelDid,
        to: [otherPartyPermanentChannelDid],
        did: otherPartyPermanentChannelDid,
        notificationToken: notificationToken,
        attachments: outgoingAttachments,
      ).toPlainTextMessage(),
      senderDidManager: permanentChannelDidManager,
      recipientDidDocument: otherPartyPermanentChannelDidDocument,
      mediatorDid: channel.mediatorDid,
    );
  }

  Future<void> _sendAgentChannelInaugurationMessage({
    required Channel channel,
    required DidManager permanentChannelDidManager,
    required String permanentChannelDid,
    required String agentPermanentChannelDid,
    required String otherPartyPermanentChannelDid,
    required String otherPartyNotificationToken,
  }) async {
    final agentDidDocument = await _didResolver.resolveDid(
      agentPermanentChannelDid,
    );

    return mediatorService.sendMessage(
      protocol.AgentChannelInauguration.create(
        from: permanentChannelDid,
        to: [agentPermanentChannelDid],
        otherPartyPermanentChannelDid: otherPartyPermanentChannelDid,
        otherPartyNotificationToken: otherPartyNotificationToken,
        offerLink: channel.offerLink,
        publishOfferDid: channel.publishOfferDid,
        contactCard: channel.otherPartyContactCard,
      ).toPlainTextMessage(),
      senderDidManager: permanentChannelDidManager,
      recipientDidDocument: agentDidDocument,
      mediatorDid: channel.mediatorDid,
    );
  }

  Future<void> _updateMediatorAcls({
    required DidManager permanentChannelDidManager,
    required String permanentChannelDid,
    required DidManager acceptOfferDidManager,
    required String acceptOfferDid,
    required String otherPartyPermanentChannelDid,
    required String messageFrom,
    required String mediatorDid,
  }) {
    return Future.wait([
      mediatorService.updateAcl(
        ownerDidManager: permanentChannelDidManager,
        mediatorDid: mediatorDid,
        acl: AccessListAdd(
          ownerDid: permanentChannelDid,
          granteeDids: [otherPartyPermanentChannelDid],
        ),
      ),
      mediatorService.updateAcl(
        ownerDidManager: acceptOfferDidManager,
        mediatorDid: mediatorDid,
        acl: AccessListRemove(
          ownerDid: acceptOfferDid,
          granteeDids: [messageFrom],
        ),
      ),
    ]);
  }

  Future<String> _registerNotificationToken(
    String myDid,
    String theirDid,
  ) async {
    final methodName = '_registerNotificationToken';
    logger.info(
      'Started registering notification token for myDid: '
      '${myDid.topAndTail()} and theirDid: ${theirDid.topAndTail()}',
      name: methodName,
    );

    final result = await _controlPlaneSDK.execute(
      RegisterNotificationCommand(
        myDid: myDid,
        theirDid: theirDid,
        device: _controlPlaneSDK.device,
      ),
    );

    final notificationToken = result.notificationToken;

    if (notificationToken == null) {
      final message =
          'Error registering notification token for ${myDid.topAndTail()} '
          'and ${theirDid.topAndTail()}';
      logger.error(message, name: methodName);
      throw Exception(message);
    }

    logger.info(
      'Completed registering notification token for myDid: '
      '${myDid.topAndTail()} and theirDid: ${theirDid.topAndTail()}',
      name: methodName,
    );
    return notificationToken;
  }

  Future<void> _notifyChannel({
    required String notificationToken,
    required String did,
  }) async {
    try {
      await _controlPlaneSDK.execute(
        NotifyChannelCommand(
          notificationToken: notificationToken,
          did: did,
          type: 'channel-inauguration', // TODO: move to enum
        ),
      );
    } catch (e, stackTrace) {
      logger.error(
        '''Failed to send channel-inauguration notification for did: ${did.topAndTail()}''',
        error: e,
        stackTrace: stackTrace,
        name: '_notifyChannel',
      );
    }
  }
}
