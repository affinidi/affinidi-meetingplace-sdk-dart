import '../entity/channel.dart';
import 'package:ssi/ssi.dart';

import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:meeting_place_mediator/meeting_place_mediator.dart';
import '../utils/attachment.dart';
import '../protocol/protocol.dart';
import '../utils/string.dart';
import 'base_event_handler.dart';
import 'exceptions/empty_message_list_exception.dart';

class OfferFinalisedEventHandler extends BaseEventHandler {
  OfferFinalisedEventHandler({
    required super.wallet,
    required super.connectionOfferRepository,
    required super.channelRepository,
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

  // TODO: move to service?
  Future<List<Channel>> process(OfferFinalised event) async {
    final methodName = 'process';
    try {
      logger.info(
        'Started processing OfferFinalised event for offerLink: ${event.offerLink}',
        name: methodName,
      );

      final connection = await findConnectionByOfferLink(event.offerLink);
      if (connection.isFinalised) {
        throw Exception(
          'Connection offer ${connection.offerLink} already finalised',
        );
      }

      final acceptOfferDid = connection.acceptOfferDid;
      final permanentChannelDid = connection.permanentChannelDid;

      if (acceptOfferDid == null || permanentChannelDid == null) {
        throw Exception(
          'Connection offer ${connection.offerLink} is missing acceptOfferDid or permanentChannelDid',
        );
      }

      final channel = await findChannelByDid(permanentChannelDid);

      final acceptOfferDidManager = await connectionManager.getDidManagerForDid(
        wallet,
        acceptOfferDid,
      );

      final acceptOfferDidDocument = await acceptOfferDidManager
          .getDidDocument();

      final permenantChannelDid = await connectionManager.getDidManagerForDid(
        wallet,
        permanentChannelDid,
      );

      final permanentChannelDidDocument = await permenantChannelDid
          .getDidDocument();

      final messages = await fetchMessagesFromMediatorWithRetry(
        didManager: acceptOfferDidManager,
        mediatorDid: connection.mediatorDid,
        messageType: MeetingPlaceProtocol.connectionRequestApproval,
      );

      // TODO: handle duplicates
      for (final result in messages) {
        final message = result.plainTextMessage;

        logger.info(
          'Found ConnectionInvitationAccepted. Their channel is ${message.body!['channel_did']}',
          name: methodName,
        );

        final otherPartyCard = getContactCardDataOrEmptyFromAttachments(
          message.attachments,
        );

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

        final otherPartyPermanentChannelDidDocument = await _didResolver
            .resolveDid(otherPartyPermanentChannelDid);

        await mediatorService.sendMessage(
          ChannelInauguration.create(
            from: permanentChannelDidDocument.id,
            to: [otherPartyPermanentChannelDid],
            did: otherPartyPermanentChannelDid,
            notificationToken: notificationToken,
          ).toPlainTextMessage(),
          senderDidManager: permenantChannelDid,
          recipientDidDocument: otherPartyPermanentChannelDidDocument,
          mediatorDid: connection.mediatorDid,
        );

        channel.notificationToken = notificationToken;
        channel.otherPartyNotificationToken = event.notificationToken;
        channel.otherPartyPermanentChannelDid = otherPartyPermanentChannelDid;
        channel.outboundMessageId = message.id;
        channel.otherPartyContactCard = otherPartyCard;
        channel.status = ChannelStatus.inaugurated;
        await channelRepository.updateChannel(channel);

        final approvedConnection = connection.finalised(
          outboundMessageId: message.id,
          otherPartyPermanentChannelDid: otherPartyPermanentChannelDid,
          notificationToken: notificationToken,
          otherPartyNotificationToken: event.notificationToken,
        );

        await connectionOfferRepository.updateConnectionOffer(
          approvedConnection,
        );

        await _notifyChannel(
          notificationToken: event.notificationToken,
          did: otherPartyPermanentChannelDid,
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
        return [channel];
      }

      logger.warning(
        'No valid ConnectionRequestApproval message found for offerLink: ${event.offerLink}',
        name: methodName,
      );
      return [];
    } on EmptyMessageListException {
      logger.error(
        'No messages found to process for event of type ${ControlPlaneEventType.OfferFinalised}',
        name: methodName,
      );
      return [];
    } catch (e, stackTrace) {
      logger.error(
        'Failed to process event of type ${ControlPlaneEventType.OfferFinalised}',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );
      rethrow;
    }
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
