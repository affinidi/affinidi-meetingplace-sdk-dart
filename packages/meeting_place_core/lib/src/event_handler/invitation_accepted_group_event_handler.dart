import 'package:didcomm/didcomm.dart';
import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import '../entity/entity.dart';
import '../protocol/protocol.dart';
import '../repository/group_repository.dart';

import '../service/group/group_exception.dart';
import '../service/mediator/fetch_messages_options.dart';
import '../utils/string.dart';
import 'base_event_handler.dart';
import 'exceptions/invitation_accepted_group_exception.dart';

class InvitationGroupAcceptedEventHandler
    extends BaseEventHandler<InvitationGroupAccept> {
  InvitationGroupAcceptedEventHandler({
    required super.wallet,
    required super.connectionOfferRepository,
    required super.channelService,
    required super.connectionManager,
    required super.mediatorService,
    required super.logger,
    required super.options,
    required GroupRepository groupRepository,
  }) : _groupRepository = groupRepository;

  final GroupRepository _groupRepository;

  // This event is handled on the device of the group admin after a potential
  // new member accepted the group offer.
  Future<List<Channel>> process(InvitationGroupAccept event) async {
    logger.info('''Started processing InvitationGroupAccept event
      for offerLink: ${event.offerLink}''', name: 'process');

    final connection = await findConnectionByOfferLink(event.offerLink);
    if (connection.permanentChannelDid != null) {
      logger.info('''InvitationGroupAccept event ignored: connection is already
        associated with a permanent channel DID''', name: 'process');
      return [];
    }

    if (connection.type != ConnectionOfferType.meetingPlaceInvitation) {
      logger.info(
        '''Skipping processing: connection offer is not of
        type ${ConnectionOfferType.meetingPlaceInvitation.name}''',
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
        filterByMessageTypes: [
          MeetingPlaceProtocol.invitationAcceptanceGroup.value,
        ],
      ),
    );
  }

  @override
  Future<Channel> processMessage(
    PlainTextMessage message, {
    required InvitationGroupAccept event,
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
      throw ArgumentError('''Message must have a sender (from) to process
        InvitationGroupAccept message''');
    }

    final group = await _findGroupByOfferLink(event.offerLink);
    final groupChannel = await channelService
        .getChannelByOtherPartyPermanentChannelDid(group.did);

    final invitationAcceptance = InvitationAcceptanceGroup.fromPlainTextMessage(
      message,
    );
    final otherPartyPermanentChannelDid = invitationAcceptance.body.channelDid;

    logger.info(
      'Acceptor\'s permanent did is $otherPartyPermanentChannelDid',
      name: 'processMessage',
    );

    final otherPartyContactCard = invitationAcceptance.contactCard;
    if (otherPartyContactCard == null) {
      throw InvitationAcceptedGroupException.contactCardNotPresent();
    }

    // Insert the new pendingApproval member atomically, only when no row for
    // this DID already exists. Writing just this one row (never a full
    // member-list replace) means a concurrent approve's status change is never
    // lost, and a re-delivered accept event is a no-op.
    await _groupRepository.addMemberIfAbsent(
      group.id,
      GroupMember.pendingMember(
        did: otherPartyPermanentChannelDid,
        contactCard: otherPartyContactCard,
      ),
    );
    logger.info(
      'Persisted pendingApproval entry for '
      '${otherPartyPermanentChannelDid.topAndTail()} '
      '(no-op if already present).',
      name: 'processMessage',
    );

    final channel = Channel(
      offerLink: connection.offerLink,
      publishOfferDid: connection.publishOfferDid,
      acceptOfferDid: messageFrom,
      mediatorDid: connection.mediatorDid,
      permanentChannelDid: group.did,
      otherPartyPermanentChannelDid: otherPartyPermanentChannelDid,
      status: ChannelStatus.waitingForApproval,
      type: ChannelType.group,
      transport: ChannelTransport.matrix,
      isConnectionInitiator: true,
      contactCard: connection.contactCard,
      otherPartyContactCard: otherPartyContactCard,
      externalRef: connection.externalRef,
    );

    await channelService.persistChannel(channel);
    return groupChannel;
  }

  Future<Group> _findGroupByOfferLink(String offerLink) async {
    return await _groupRepository.findGroupByOfferLink(offerLink) ??
        (throw GroupException.notFoundError());
  }
}
