import '../entity/channel.dart';
import '../protocol/message/channel_inauguration.dart';
import '../protocol/meeting_place_protocol.dart';
import 'package:ssi/ssi.dart';

import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:meeting_place_mediator/meeting_place_mediator.dart';
import '../messages/utils.dart';
import '../service/mediator/fetch_messages_options.dart';
import '../utils/string.dart';
import 'base_event_handler.dart';

class OfferFinalisedEventHandler extends BaseEventHandler {
  OfferFinalisedEventHandler({
    required super.wallet,
    required super.connectionOfferRepository,
    required super.channelRepository,
    required super.connectionManager,
    required super.mediatorService,
    required super.logger,
    required ControlPlaneSDK controlPlaneSDK,
    required DidResolver didResolver,
  })  : _controlPlaneSDK = controlPlaneSDK,
        _didResolver = didResolver;

  final ControlPlaneSDK _controlPlaneSDK;
  final DidResolver _didResolver;

  // TODO: move to service?
  Future<Channel?> process(OfferFinalised event) async {
    final methodName = 'process';
    logger.info(
      'Started processing OfferFinalised event for offerLink: ${event.offerLink}',
      name: methodName,
    );

    final connection = await findConnectionByOfferLink(event.offerLink);
    if (connection.isFinalised()) {
      throw Exception(
          'Connection offer ${connection.offerLink} already finalised');
    }

    final acceptOfferDid = connection.acceptOfferDid;
    final permanentChannelDid = connection.permanentChannelDid;

    if (acceptOfferDid == null || permanentChannelDid == null) {
      throw Exception(
          'Connection offer ${connection.offerLink} is missing acceptOfferDid or permanentChannelDid');
    }

    final channel = await findChannelByOfferLink(event.offerLink);

    final acceptOfferDidManager =
        await connectionManager.getDidManagerForDid(wallet, acceptOfferDid);

    final acceptOfferDidDocument = await acceptOfferDidManager.getDidDocument();

    final permenantChannelDid = await connectionManager.getDidManagerForDid(
        wallet, permanentChannelDid);

    final permanentChannelDidDocument =
        await permenantChannelDid.getDidDocument();

    final messages = await mediatorService.fetchMessages(
      didManager: acceptOfferDidManager,
      mediatorDid: connection.mediatorDid,
      options: FetchMessagesOptions(
        filterByMessageTypes: [MeetingPlaceProtocol.connectionAccepted.value],
      ),
    );

    // TODO: handle duplicates
    for (final result in messages) {
      final message = result.plainTextMessage;

      logger.info(
        'Found ConnectionInvitationAccepted. Their channel is ${message.body!['channel_did']}',
        name: methodName,
      );

      final otherPartyVCard =
          getVCardDataOrEmptyFromAttachments(message.attachments);

      final otherPartyPermanentChannelDid =
          message.body!['channel_did'] as String;

      final notificationToken = await _registerNotificationToken(
        connection.permanentChannelDid!,
        otherPartyPermanentChannelDid,
      );

      await Future.wait([
        mediatorService.updateAcl(
          ownerDidManager: permenantChannelDid,
          mediatorDid: connection.mediatorDid,
          acl: AccessListAdd(
            ownerDid: permanentChannelDidDocument.id,
            granteeDids: [otherPartyPermanentChannelDid],
          ),
        ),
        mediatorService.updateAcl(
          ownerDidManager: acceptOfferDidManager,
          mediatorDid: connection.mediatorDid,
          acl: AccessListRemove(
            ownerDid: acceptOfferDidDocument.id,
            granteeDids: [message.from!],
          ),
        ),
      ]);

      final otherPartyPermanentChannelDidDocument =
          await _didResolver.resolveDid(otherPartyPermanentChannelDid);

      await mediatorService.sendMessage(
        ChannelInauguration.create(
          from: permanentChannelDidDocument.id,
          to: [otherPartyPermanentChannelDid],
          did: otherPartyPermanentChannelDid,
          notificationToken: notificationToken,
        ),
        senderDidManager: permenantChannelDid,
        recipientDidDocument: otherPartyPermanentChannelDidDocument,
        mediatorDid: connection.mediatorDid,
      );

      channel.notificationToken = notificationToken;
      channel.otherPartyNotificationToken = event.notificationToken;
      channel.otherPartyPermanentChannelDid = otherPartyPermanentChannelDid;
      channel.outboundMessageId = message.id;
      channel.otherPartyVCard = otherPartyVCard;
      channel.status = ChannelStatus.inaugaurated;
      await channelRepository.updateChannel(channel);

      final approvedConnection = connection.finalised(
        outboundMessageId: message.id,
        otherPartyPermanentChannelDid: otherPartyPermanentChannelDid,
        notificationToken: notificationToken,
        otherPartyNotificationToken: event.notificationToken,
      );

      await connectionOfferRepository.updateConnectionOffer(approvedConnection);

      await _controlPlaneSDK.execute(
        NotifyChannelCommand(
          notificationToken: event.notificationToken,
          did: otherPartyPermanentChannelDid,
          type: 'channel-inauguration', // TODO: move to enum
        ),
      );

      await mediatorService.deletedMessages(
        didManager: acceptOfferDidManager,
        mediatorDid: connection.mediatorDid,
        messageHashes: [result.messageHash!],
      );

      logger.info(
        'Completed processing OfferFinalised event for offerLink: ${event.offerLink}',
        name: methodName,
      );
      return channel;
    }

    logger.warning(
      'No valid ConnectionInvitationAccepted message found for offerLink: ${event.offerLink}',
      name: methodName,
    );
    return null;
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
}
