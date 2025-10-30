import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import '../entity/entity.dart';
import '../protocol/protocol.dart';
import '../repository/group_repository.dart';

import '../service/group/group_exception.dart';
import '../messages/utils.dart';
import 'base_event_handler.dart';
import 'exceptions/empty_message_list_exception.dart';

class InvitationGroupAcceptedEventHandler extends BaseEventHandler {
  InvitationGroupAcceptedEventHandler({
    required super.wallet,
    required super.connectionOfferRepository,
    required super.channelRepository,
    required super.connectionManager,
    required super.mediatorService,
    required super.logger,
    required super.options,
    required GroupRepository groupRepository,
  }) : _groupRepository = groupRepository;

  final GroupRepository _groupRepository;

  // This event is handled on the device of the group admin after a potential
  // new member accepted the group offer.
  Future<Channel?> process(InvitationGroupAccept event) async {
    final methodName = 'process';
    try {
      logger.info(
        'Started processing InvitationGroupAccept event for offerLink: ${event.offerLink}',
        name: methodName,
      );

      final connection = await findConnectionByOfferLink(event.offerLink);
      if (connection.permanentChannelDid != null) {
        logger.info(
          'InvitationGroupAccept event ignored: connection is already associated with a permanent channel DID',
          name: methodName,
        );
        return null;
      }

      if (connection.type != ConnectionOfferType.meetingPlaceInvitation) {
        logger.info(
          'Skipping processing: connection offer is not of type ${ConnectionOfferType.meetingPlaceInvitation.name}',
          name: methodName,
        );
        return null;
      }

      final group = await _findGroupByOfferLink(event.offerLink);

      final groupChannel = await channelRepository
              .findChannelByOtherPartyPermanentChannelDid(group.did) ??
          (throw Exception('Channel not found for group: ${group.did}'));

      final publishedOfferDidManager = await connectionManager
          .getDidManagerForDid(wallet, connection.publishOfferDid);

      final messages = await fetchMessagesFromMediatorWithRetry(
        didManager: publishedOfferDidManager,
        mediatorDid: connection.mediatorDid,
        messageType: MeetingPlaceProtocol.connectionSetupGroup,
      );

      // TODO: ensure duplicate requests are handled correctly
      for (final result in messages) {
        final message = result.plainTextMessage;

        final publicKey = message.body!['public_key'] as String;
        final otherPartyPermanentChannelDid =
            message.body!['channel_did'] as String;

        logger.info(
          'Acceptor\'s permanent did is $otherPartyPermanentChannelDid',
          name: methodName,
        );

        final otherPartyVCard = getVCardDataOrEmptyFromAttachments(
          message.attachments,
        );

        final acceptOfferDid = message.from!;
        group.members.add(
          GroupMember(
            did: otherPartyPermanentChannelDid,
            dateAdded: DateTime.now().toUtc(),
            publicKey: publicKey,
            status: GroupMemberStatus.pendingApproval,
            membershipType: GroupMembershipType.member,
            vCard: otherPartyVCard ?? VCard.empty(),
          ),
        );

        await _groupRepository.updateGroup(group);

        final channel = Channel(
          offerLink: connection.offerLink,
          publishOfferDid: connection.publishOfferDid,
          acceptOfferDid: acceptOfferDid,
          mediatorDid: connection.mediatorDid,
          permanentChannelDid: group.did,
          otherPartyPermanentChannelDid: otherPartyPermanentChannelDid,
          status: ChannelStatus.waitingForApproval,
          type: ChannelType.group,
          vCard: connection.vCard,
          otherPartyVCard: otherPartyVCard,
          externalRef: connection.externalRef,
        );

        await channelRepository.createChannel(channel);
        await mediatorService.deletedMessages(
          didManager: publishedOfferDidManager,
          mediatorDid: connection.mediatorDid,
          messageHashes: [result.messageHash!],
        );

        logger.info(
          'Completed processing InvitationGroupAccept event for offerLink: ${event.offerLink}',
          name: methodName,
        );
        return groupChannel;
      }

      logger.warning(
        'No valid ConnectionSetupGroup message found for offerLink: ${event.offerLink}',
        name: methodName,
      );
      return null;
    } on EmptyMessageListException {
      logger.error(
        'No messages found to process for event of type ${ControlPlaneEventType.InvitationGroupAccept}',
        name: methodName,
      );
      return null;
    } catch (e, stackTrace) {
      logger.error(
        'Failed to process event of type ${ControlPlaneEventType.InvitationGroupAccept}',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );
      rethrow;
    }
  }

  Future<Group> _findGroupByOfferLink(String offerLink) async {
    return await _groupRepository.getGroupByOfferLink(offerLink) ??
        (throw GroupException.notFoundError());
  }
}
