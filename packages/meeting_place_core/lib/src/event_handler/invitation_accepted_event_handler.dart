import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import '../../meeting_place_core.dart';
import '../service/mediator/fetch_messages_options.dart';
import '../utils/string.dart';
import 'base_event_handler.dart';
import 'exceptions/empty_message_list_exception.dart';

class InvitationAcceptedEventHandler
    extends BaseEventHandler<InvitationAccept> {
  InvitationAcceptedEventHandler({
    required super.wallet,
    required super.connectionOfferRepository,
    required super.channelService,
    required super.connectionManager,
    required super.mediatorService,
    required super.options,
    required super.logger,
  });

  Future<List<Channel>> process(InvitationAccept event) async {
    final methodName = 'process';
    logger.info(
      '''Started processing ${ControlPlaneEventType.InvitationAccept} event
      with offerLink: ${event.offerLink}''',
      name: methodName,
    );

    try {
      final connection = await findConnectionByOfferLink(event.offerLink);

      if (connection.type != ConnectionOfferType.meetingPlaceInvitation) {
        logger.warning(
          '''Skipping processing: connection offer is not of type
          ${ConnectionOfferType.meetingPlaceInvitation.name}''',
          name: methodName,
        );
        return [];
      }

      final publishedOfferDidManager = await connectionManager
          .getDidManagerForDid(wallet, connection.publishOfferDid);

      return processEvent(
        event: event,
        didManager: publishedOfferDidManager,
        mediatorDid: connection.mediatorDid,
        connection: connection,
        fetchMessageOptions: FetchMessagesOptions(
          filterByMessageTypes: [
            MeetingPlaceProtocol.invitationAcceptance.value,
          ],
        ),
      );
    } on EmptyMessageListException {
      logger.warning(
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

  @override
  Future<Channel> processMessage(
    PlainTextMessage message, {
    required InvitationAccept event,
    ConnectionOffer? connection,
    Channel? channel,
  }) async {
    if (connection == null) {
      throw ArgumentError(
        'ConnectionOffer must be provided to process message',
      );
    }

    final messageFrom = message.from;
    if (messageFrom == null) {
      throw ArgumentError(
        'Message must have a "from" field to process invitation acceptance',
      );
    }

    final invitationAcceptance = InvitationAcceptance.fromPlainTextMessage(
      message,
    );

    logger.info(
      '''Acceptor's permanent did is
      ${invitationAcceptance.body.channelDid.topAndTail()}''',
      name: 'processMessage',
    );

    final channel = Channel(
      offerLink: connection.offerLink,
      publishOfferDid: connection.publishOfferDid,
      acceptOfferDid: messageFrom,
      mediatorDid: connection.mediatorDid,
      otherPartyPermanentChannelDid: invitationAcceptance.body.channelDid,
      outboundMessageId: message.id,
      status: ChannelStatus.waitingForApproval,
      type: ChannelType.individual,
      isConnectionInitiator: true,
      contactCard: connection.contactCard,
      otherPartyContactCard: invitationAcceptance.contactCard,
      externalRef: connection.externalRef,
    );

    await channelService.persistChannel(channel);
    return channel;
  }
}
