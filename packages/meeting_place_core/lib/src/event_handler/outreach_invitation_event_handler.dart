import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import '../../meeting_place_core.dart';
import '../entity/group_connection_offer.dart';
import '../protocol/message/outreach_invitation/outreach_invitation.dart';
import '../service/connection_service.dart';
import '../service/group.dart';
import '../service/mediator/fetch_messages_options.dart';
import 'base_event_handler.dart';

class OutreachInvitationEventHandler
    extends BaseEventHandler<InvitationOutreach> {
  OutreachInvitationEventHandler({
    required super.wallet,
    required super.connectionOfferRepository,
    required super.channelService,
    required super.connectionManager,
    required super.mediatorService,
    required super.logger,
    required super.options,
    required ConnectionService connectionService,
    required GroupService groupService,
  }) : _connectionService = connectionService,
       _groupService = groupService;

  final ConnectionService _connectionService;
  final GroupService _groupService;

  Future<List<Channel>> process(InvitationOutreach event) async {
    logger.info('''Started processing OutreachInvitation event with
      offerLink: ${event.offerLink}''', name: 'process');

    final connection = await findConnectionByOfferLink(event.offerLink);
    if (connection.type != ConnectionOfferType.meetingPlaceOutreachInvitation) {
      logger.warning(
        '''Connection offer is not of
          type ${ConnectionOfferType.meetingPlaceOutreachInvitation.name}''',
        name: 'process',
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
        filterByMessageTypes: [MeetingPlaceProtocol.outreachInvitation.value],
      ),
    );
  }

  @override
  Future<Channel> processMessage(
    PlainTextMessage message, {
    required InvitationOutreach event,
    ConnectionOffer? connection,
    Channel? channel,
  }) async {
    if (connection == null) {
      throw ArgumentError(
        'ConnectionOffer must be provided to process message',
      );
    }

    final outreachInvitation = OutreachInvitation.fromPlainTextMessage(message);
    final findOfferResult = await _connectionService.findOffer(
      mnemonic: outreachInvitation.body.mnemonic,
    );

    final offer = findOfferResult.$1;
    if (offer == null) {
      throw StateError(
        'No offer found for mnemonic: ${outreachInvitation.body.mnemonic}',
      );
    }

    if (offer is GroupConnectionOffer) {
      final acceptance = await _groupService.acceptGroupOffer(
        wallet: wallet,
        connectionOffer: offer,
        card: connection.contactCard,
        senderInfo: 'Somebody',
      );

      final permanentChannelDidDocument = await acceptance.permanentChannelDid
          .getDidDocument();
      return channelService.findChannelByDid(permanentChannelDidDocument.id);
    }

    final acceptance = await _connectionService.acceptOffer(
      wallet: wallet,
      connectionOffer: offer,
      contactCard: connection.contactCard,
      senderInfo: 'Somebody',
    );

    return acceptance.channel;
  }
}
