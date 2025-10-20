import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:meeting_place_mediator/meeting_place_mediator.dart';
import '../entity/channel.dart';
import '../entity/group_connection_offer.dart';
import '../service/mediator/fetch_messages_options.dart';
import '../utils/string.dart';
import 'base_event_handler.dart';
import 'exceptions/group_membership_finalized_exception.dart';
import '../protocol/message/group_member_inauguration.dart';
import '../protocol/mpx_protocol.dart';
import '../repository/repository.dart';
import '../service/group/group_exception.dart';
import 'package:ssi/ssi.dart';
import '../entity/group.dart';
import '../entity/group_member.dart';

class MemberDidMismatchException implements Exception {}

class GroupMembershipFinalisedEventHandler extends BaseEventHandler {
  GroupMembershipFinalisedEventHandler({
    required super.wallet,
    required super.connectionOfferRepository,
    required super.channelRepository,
    required super.connectionManager,
    required super.mediatorService,
    required super.logger,
    required ControlPlaneSDK controlPlaneSDK,
    required GroupRepository groupRepository,
  })  : _groupRepository = groupRepository,
        _controlPlaneSDK = controlPlaneSDK;

  final ControlPlaneSDK _controlPlaneSDK;
  final GroupRepository _groupRepository;

  Future<Channel?> process(GroupMembershipFinalised event) async {
    final methodName = 'process';
    logger.info(
      'Starting processing event of type ${ControlPlaneEventType.GroupMembershipFinalised}',
      name: methodName,
    );

    try {
      final connection = await findConnectionByOfferLink(event.offerLink);
      final permanentChannelDid = connection.permanentChannelDid;

      if (permanentChannelDid == null) {
        throw Exception(
            'Connection offer ${connection.offerLink} is missing permanentChannelDid');
      }

      if (connection is! GroupConnectionOffer) {
        logger.error(
          'Connection offer is not a GroupConnectionOffer for offer link: ${event.offerLink}',
          name: methodName,
        );
        throw GroupMembershipFinalizedException.groupConnectionOfferRequired(
          offerLink: event.offerLink,
        );
      }

      if (connection.isFinalised()) {
        throw GroupMembershipFinalizedException
            .connectionOfferAlreadyFinalizedException(
          offerLink: event.offerLink,
        );
      }

      final group = await _findGroupByOfferLink(connection.offerLink);
      final channel = await findChannelByOfferLink(connection.offerLink);

      final didManager = await connectionManager.getDidManagerForDid(
          wallet, permanentChannelDid);

      final messages = await mediatorService.fetchMessages(
        didManager: didManager,
        mediatorDid: connection.mediatorDid,
        options: FetchMessagesOptions(
          filterByMessageTypes: [
            MeetingPlaceProtocol.groupMemberInauguration.value,
          ],
        ),
      );

      // TODO: handle duplicates
      for (final result in messages) {
        final message = result.plainTextMessage;
        final groupMemberInaugurationMessage =
            GroupMemberInauguration.fromMessage(message);

        if (groupMemberInaugurationMessage.memberDid !=
            connection.permanentChannelDid!) {
          logger.error(
            'Member DID mismatch: expected ${connection.permanentChannelDid?.topAndTail()}, found ${groupMemberInaugurationMessage.memberDid.topAndTail()}',
            name: methodName,
          );
          throw MemberDidMismatchException();
        }

        final notificationToken = await _registerNotificationToken(
          permanentChannelDid,
          groupMemberInaugurationMessage.groupDid,
        );

        final admin = groupMemberInaugurationMessage.members.firstWhere(
          (member) => member.isAdmin(),
        );

        await Future.wait([
          mediatorService.updateAcl(
            ownerDidManager: didManager,
            mediatorDid: connection.mediatorDid,
            acl: AccessListRemove(
              ownerDid: permanentChannelDid,
              granteeDids: [message.from!],
            ),
          ),

          // allow group admin to send messages to member directly for profile
          // request
          mediatorService.updateAcl(
            ownerDidManager: didManager,
            mediatorDid: connection.mediatorDid,
            acl: AccessListAdd(
              ownerDid: permanentChannelDid,
              granteeDids: [admin.did],
            ),
          ),

          _allowGroupToSendMessagesToPermanetChannelDid(
            permanentChannelDid: didManager,
            mediatorDid: connection.mediatorDid,
            groupDid: groupMemberInaugurationMessage.groupDid,
          ),
        ]);

        // TODO: improve update logic
        final updatedGroup = _updateLocalCopyOfGroupMembers(
          group,
          groupMemberInaugurationMessage,
        );

        await _groupRepository.createGroup(updatedGroup);
        await _groupRepository.removeGroup(group);

        channel.otherPartyPermanentChannelDid = updatedGroup.did;
        await channelRepository.updateChannel(channel);

        final finalisedConnection = connection.groupFinalise(
          groupId: updatedGroup.id,
          groupDid: updatedGroup.did,
          seqNo: event.startSeqNo,
          notificationToken: notificationToken,
        );

        await connectionOfferRepository.updateConnectionOffer(
          finalisedConnection,
        );

        channel.otherPartyPermanentChannelDid = updatedGroup.did;
        channel.seqNo = event.startSeqNo;
        channel.notificationToken = notificationToken;
        channel.status = ChannelStatus.inaugaurated;
        await channelRepository.updateChannel(channel);

        await mediatorService.deletedMessages(
          didManager: didManager,
          mediatorDid: connection.mediatorDid,
          messageHashes: [result.messageHash!],
        );

        logger.info(
          'Completely successfully processed ${MeetingPlaceProtocol.groupMemberInauguration.value} message for group DID: ${updatedGroup.did.topAndTail()}',
          name: methodName,
        );
        return channel;
      }

      logger.warning(
        'No ${MeetingPlaceProtocol.groupMemberInauguration.value} message found for processing',
        name: methodName,
      );
      return null;
    } catch (e, stackTrace) {
      logger.error(
        'Failed to process event of type ${ControlPlaneEventType.GroupMembershipFinalised}',
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
      'Registering notification token for myDid: ${myDid.topAndTail()}, theirDid: ${theirDid.topAndTail()}',
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
      throw Exception('Error registering notification token');
    }

    logger.info(
      'Successfully registered notification token: ${notificationToken.topAndTail()}',
      name: methodName,
    );
    return notificationToken;
  }

  Future<void> _allowGroupToSendMessagesToPermanetChannelDid({
    required DidManager permanentChannelDid,
    required String mediatorDid,
    required String groupDid,
  }) async {
    final methodName = '_allowGroupToSendMessagesToPermanentChannelDid';
    final permanentChannelDidDocument =
        await permanentChannelDid.getDidDocument();

    logger.info(
      'Allowing group DID: ${groupDid.topAndTail()} to send messages to permanent channel DID: ${permanentChannelDidDocument.id.topAndTail()}',
      name: methodName,
    );
    return mediatorService.updateAcl(
      ownerDidManager: permanentChannelDid,
      mediatorDid: mediatorDid,
      acl: AccessListAdd(
        ownerDid: permanentChannelDidDocument.id,
        granteeDids: [groupDid],
      ),
    );
  }

  ///
  /// Iterate the member details list and populate/update the
  /// group membership list. Note that this will cause the local
  /// store to reflect the administrator's view of the group membership
  /// list, obviously without the private details of the members.
  ///
  Group _updateLocalCopyOfGroupMembers(
    Group group,
    GroupMemberInauguration message,
  ) {
    final methodName = '_updateLocalCopyOfGroupMembers';
    logger.info(
      'Updating local copy of group members for group DID: ${group.did.topAndTail()}',
      name: methodName,
    );

    final updatedGroup = group.copyWith(
      id: message.groupId,
      did: message.groupDid,
      publicKey: message.groupPublicKey,
      ownerDid: message.adminDids[0],
      created: DateTime.now().toUtc(),
    );

    for (final member in message.members) {
      final localMemberIndex = updatedGroup.members.indexWhere(
        (lm) => lm.did == member.did,
      );

      if (localMemberIndex == -1) {
        updatedGroup.members.add(
          GroupMember(
            did: member.did,
            vCard: member.vCard,
            status: GroupMemberStatus.values.byName(member.status),
            membershipType: GroupMembershipType.values.byName(
              member.membershipType,
            ),
            publicKey: member.publicKey,
            dateAdded: DateTime.now().toUtc(),
          ),
        );
        continue;
      }

      // TODO: add test case for this specific case
      final existingMember = updatedGroup.members[localMemberIndex];
      updatedGroup.members[localMemberIndex] = existingMember.copyWith(
        vCard: member.vCard,
        dateAdded: DateTime.now().toUtc(),
        status: GroupMemberStatus.approved,
        publicKey: member.publicKey,
        membershipType: GroupMembershipType.values.byName(
          member.membershipType,
        ),
      );
    }

    logger.info(
      'Successfully updated local copy of group members for group DID: ${updatedGroup.did.topAndTail()}',
      name: methodName,
    );
    return updatedGroup;
  }

  Future<Group> _findGroupByOfferLink(String offerLink) async {
    return await _groupRepository.getGroupByOfferLink(offerLink) ??
        (throw GroupException.notFoundError());
  }
}
