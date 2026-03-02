import '../../meeting_place_core.dart';
import 'package:ssi/ssi.dart';

import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import '../service/mediator/fetch_messages_options.dart';
import '../utils/attachment.dart';
import '../protocol/protocol.dart' as protocol;
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
  }) : _controlPlaneSDK = controlPlaneSDK,
       _didResolver = didResolver;

  final ControlPlaneSDK _controlPlaneSDK;
  final DidResolver _didResolver;

  Future<List<Channel>> process(OfferFinalised event) async {
    logger.info(
      'Started processing OfferFinalised event for offerLink: ${event.offerLink}',
      name: 'process',
    );

    final connection = await findConnectionByOfferLink(event.offerLink);
    if (connection.isFinalised) {
      throw Exception(
        'Connection offer ${connection.offerLink} already finalised',
      );
    }

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

    final permanentChannelDidManager = await connectionManager
        .getDidManagerForDid(wallet, permanentChannelDid);

    final (otherPartyPermanentChannelDid, otherPartyCard) = _extractFromMessage(
      message,
    );

    final notificationToken = await _registerNotificationToken(
      permanentChannelDid,
      otherPartyPermanentChannelDid,
    );

    await _updateMediatorAcls(
      permanentChannelDidManager: permanentChannelDidManager,
      permanentChannelDid: permanentChannelDid,
      acceptOfferDidManager: acceptOfferDidManager,
      acceptOfferDid: acceptOfferDid,
      otherPartyPermanentChannelDid: otherPartyPermanentChannelDid,
      messageFrom: messageFrom,
      mediatorDid: channel.mediatorDid,
    );

    await _sendChannelInaugurationMessage(
      channel: channel,
      permanentChannelDidManager: permanentChannelDidManager,
      permanentChannelDid: permanentChannelDid,
      otherPartyPermanentChannelDid: otherPartyPermanentChannelDid,
      notificationToken: notificationToken,
    );

    await channelService.markChannelInauguratedFromWaitingForApproval(
      channel,
      notificationToken: notificationToken,
      otherPartyNotificationToken: event.notificationToken,
      otherPartyPermanentChannelDid: otherPartyPermanentChannelDid,
      outboundMessageId: message.id,
      otherPartyCard: otherPartyCard,
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

  (String, protocol.ContactCard?) _extractFromMessage(
    PlainTextMessage message,
  ) {
    final connectionRequestApprovalMessage =
        protocol.ConnectionRequestApproval.fromPlainTextMessage(message);

    final otherPartyPermanentChannelDid =
        connectionRequestApprovalMessage.body.channelDid;

    logger.info(
      '''Found ConnectionRequestApproval. Their channel
      is ${connectionRequestApprovalMessage.body.channelDid}''',
      name: 'processMessage',
    );

    final otherPartyCard = getContactCardDataOrEmptyFromAttachments(
      connectionRequestApprovalMessage.attachments,
    );

    return (otherPartyPermanentChannelDid, otherPartyCard);
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

    List<Attachment>? outgoingAttachments = await options.onBuildAttachments
        ?.call(channel);

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
      'Started registering notification token for myDid: ${myDid.topAndTail()} and theirDid: ${theirDid.topAndTail()}',
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
          'Error registering notification token for ${myDid.topAndTail()} and ${theirDid.topAndTail()}';
      logger.error(message, name: methodName);
      throw Exception(message);
    }

    logger.info(
      'Completed registering notification token for myDid: ${myDid.topAndTail()} and theirDid: ${theirDid.topAndTail()}',
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
