import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import '../entity/channel.dart';
import '../protocol/meeting_place_protocol.dart';
import '../entity/connection_offer.dart';
import '../utils/attachment.dart';
import 'base_event_handler.dart';
import 'exceptions/empty_message_list_exception.dart';

class InvitationAcceptedEventHandler extends BaseEventHandler {
  InvitationAcceptedEventHandler({
    required super.wallet,
    required super.connectionOfferRepository,
    required super.channelRepository,
    required super.connectionManager,
    required super.mediatorService,
    required super.options,
    required super.logger,
  });

  Future<List<Channel>> process(InvitationAccept event) async {
    final methodName = 'process';
    logger.info(
      'Started processing InvitationAccept event with offerLink: ${event.offerLink}',
      name: methodName,
    );

    try {
      final connection = await findConnectionByOfferLink(event.offerLink);
      if (connection.type != ConnectionOfferType.meetingPlaceInvitation) {
        logger.warning(
          'Skipping processing: connection offer is not of type ${ConnectionOfferType.meetingPlaceInvitation.name}',
          name: methodName,
        );
        return [];
      }

      final publishedOfferDidManager = await connectionManager
          .getDidManagerForDid(wallet, connection.publishOfferDid);

      final messages = await fetchMessagesFromMediatorWithRetry(
        didManager: publishedOfferDidManager,
        mediatorDid: connection.mediatorDid,
        messageType: MeetingPlaceProtocol.invitationAcceptance,
      );

      final channels = <Channel>[];

      // TODO: what if event with same offer link comes in?
      // TODO: what if process dies after first message but others are left?
      for (final result in messages) {
        final message = result.plainTextMessage;

        final otherPartyPermanentChannelDid =
            message.body!['channel_did'] as String;

        logger.info(
          'Acceptor\'s permanent did is $otherPartyPermanentChannelDid',
          name: methodName,
        );

        final otherPartyContactCard = getContactCardDataOrEmptyFromAttachments(
          message.attachments,
        );

        final acceptOfferDid = message.from!;
        final channel = Channel(
          offerLink: connection.offerLink,
          publishOfferDid: connection.publishOfferDid,
          acceptOfferDid: acceptOfferDid,
          mediatorDid: connection.mediatorDid,
          otherPartyPermanentChannelDid: otherPartyPermanentChannelDid,
          outboundMessageId: message.id,
          status: ChannelStatus.waitingForApproval,
          type: ChannelType.individual,
          contactCard: connection.contactCard,
          otherPartyContactCard: otherPartyContactCard,
          externalRef: connection.externalRef,
        );

        await channelRepository.createChannel(channel);

        await mediatorService.deletedMessages(
          didManager: publishedOfferDidManager,
          mediatorDid: connection.mediatorDid,
          messageHashes: [result.messageHash!],
        );

        logger.info(
          'Completed processing InvitationAccept event and created channel with id: ${channel.id}',
          name: methodName,
        );

        channels.add(channel);
      }

      return channels;
    } on EmptyMessageListException {
      logger.error(
        'No messages found to process for event of type ${ControlPlaneEventType.InvitationAccept}',
        name: methodName,
      );
      return [];
    } catch (e, stackTrace) {
      logger.error(
        'Failed to process event of type ${ControlPlaneEventType.InvitationAccept}',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );
      rethrow;
    }
  }
}
