import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import '../entity/channel.dart';
import '../protocol/mpx_protocol.dart';
import '../entity/connection_offer.dart';
import '../messages/utils.dart';
import '../service/mediator/fetch_messages_options.dart';
import 'base_event_handler.dart';

class InvitationAcceptedEventHandler extends BaseEventHandler {
  InvitationAcceptedEventHandler({
    required super.wallet,
    required super.connectionOfferRepository,
    required super.channelRepository,
    required super.connectionManager,
    required super.mediatorService,
    required super.logger,
  });

  // TODO: handle duplicates + offerLink batch
  Future<Channel?> process(InvitationAccept event) async {
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
        return null;
      }

      final publishedOfferDidManager = await connectionManager
          .getDidManagerForDid(wallet, connection.publishOfferDid);

      final messages = await mediatorService.fetchMessages(
        didManager: publishedOfferDidManager,
        mediatorDid: connection.mediatorDid,
        options: FetchMessagesOptions(
          filterByMessageTypes: [MeetingPlaceProtocol.connectionSetup.value],
        ),
      );

      for (final result in messages) {
        final message = result.plainTextMessage;

        final otherPartyPermanentChannelDid =
            message.body!['channel_did'] as String;

        logger.info(
          'Acceptor\'s permanent did is $otherPartyPermanentChannelDid',
          name: methodName,
        );

        final otherPartyVcard = getVCardDataOrEmptyFromAttachments(
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
          vCard: connection.vCard,
          otherPartyVCard: otherPartyVcard,
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

        return channel;
      }
      return null;
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
