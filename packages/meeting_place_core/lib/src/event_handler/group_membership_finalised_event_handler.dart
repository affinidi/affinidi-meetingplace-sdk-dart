import 'package:didcomm/didcomm.dart';
import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:meeting_place_mediator/meeting_place_mediator.dart';
import '../entity/channel.dart';
import '../entity/connection_offer.dart';
import '../entity/group_connection_offer.dart';
import '../service/mediator/fetch_messages_options.dart';
import '../utils/string.dart';
import 'base_event_handler.dart';
import 'exceptions/group_membership_finalised_exception.dart';
import '../protocol/message/group_member_inauguration/group_member_inauguration.dart';
import '../protocol/meeting_place_protocol.dart';
import '../repository/repository.dart';
import '../service/group/group_exception.dart';
import 'package:ssi/ssi.dart';
import '../entity/group.dart';
import '../entity/group_member.dart';

class MemberDidMismatchException implements Exception {}

class GroupMembershipFinalisedEventHandler
    extends BaseEventHandler<GroupMembershipFinalised> {
  GroupMembershipFinalisedEventHandler({
    required super.wallet,
    required super.connectionOfferRepository,
    required super.channelService,
    required super.connectionManager,
    required super.mediatorService,
    required super.logger,
    required super.options,
    required ControlPlaneSDK controlPlaneSDK,
    required GroupRepository groupRepository,
  }) : _groupRepository = groupRepository,
       _controlPlaneSDK = controlPlaneSDK;

  final ControlPlaneSDK _controlPlaneSDK;
  final GroupRepository _groupRepository;

  Future<List<Channel>> process(GroupMembershipFinalised event) async {
    logger.info('''Starting processing event of type
      ${ControlPlaneEventType.GroupMembershipFinalised}''', name: 'process');

    final connection = await findConnectionByOfferLink(event.offerLink);
    final permanentChannelDid = connection.permanentChannelDid;

    if (permanentChannelDid == null) {
      throw Exception(
        'Connection offer ${connection.offerLink} is missing permanentChannelDid',
      );
    }

    if (connection is! GroupConnectionOffer) {
      logger.error('''Connection offer is not a GroupConnectionOffer for offer
          link: ${event.offerLink}''', name: 'process');

      throw GroupMembershipFinalisedException.groupConnectionOfferRequired(
        offerLink: event.offerLink,
      );
    }

    if (connection.isFinalised) {
      logger.error('''Connection offer is already finalised for offer
          link: ${event.offerLink}''', name: 'process');

      throw GroupMembershipFinalisedException.connectionOfferAlreadyFinalizedException(
        offerLink: event.offerLink,
      );
    }

    final channel = await channelService.findChannelByDid(permanentChannelDid);
    final didManager = await connectionManager.getDidManagerForDid(
      wallet,
      permanentChannelDid,
    );

    return processEvent(
      event: event,
      didManager: didManager,
      mediatorDid: connection.mediatorDid,
      connection: connection,
      channel: channel,
      fetchMessageOptions: FetchMessagesOptions(
        filterByMessageTypes: [
          MeetingPlaceProtocol.groupMemberInauguration.value,
        ],
      ),
    );
  }

  @override
  Future<Channel> processMessage(
    PlainTextMessage message, {
    required GroupMembershipFinalised event,
    ConnectionOffer? connection,
    Channel? channel,
  }) async {
    if (connection == null || connection is! GroupConnectionOffer) {
      throw ArgumentError(
        'GroupConnectionOffer must be provided to process message',
      );
    }

    if (channel == null) {
      throw ArgumentError(
        '''Channel must be provided to process group member inauguration
        message''',
      );
    }

    final permanentChannelDid = connection.permanentChannelDid;
    if (permanentChannelDid == null) {
      throw ArgumentError(
        '''Connection offer must have a permanentChannelDid to process group
        member inauguration message''',
      );
    }

    final messageFrom = message.from;
    if (messageFrom == null) {
      throw ArgumentError(
        '''Message must have a sender (from) to process group member
        inauguration message''',
      );
    }

    final groupMemberInaugurationMessage =
        GroupMemberInauguration.fromPlainTextMessage(message);

    if (groupMemberInaugurationMessage.body.memberDid != permanentChannelDid) {
      logger.error(
        '''Member DID mismatch: expected
        ${permanentChannelDid.topAndTail()}, found
        ${groupMemberInaugurationMessage.body.memberDid.topAndTail()}''',
        name: 'processMessage',
      );
      throw MemberDidMismatchException();
    }

    final notificationToken = await _registerNotificationToken(
      permanentChannelDid,
      groupMemberInaugurationMessage.body.groupDid,
    );

    final group = await _findGroupByOfferLink(connection.offerLink);
    final admin = groupMemberInaugurationMessage.body.members.firstWhere(
      (member) => member.membershipType == GroupMembershipType.admin.name,
    );

    final didManager = await connectionManager.getDidManagerForDid(
      wallet,
      permanentChannelDid,
    );

    await _updateMediatorAcls(
      didManager: didManager,
      permanentChannelDid: permanentChannelDid,
      adminDid: admin.did,
      groupDid: group.did,
      messageFrom: messageFrom,
      mediatorDid: connection.mediatorDid,
    );

    // TODO: improve update logic
    final updatedGroup = _updateLocalCopyOfGroupMembers(
      group: group,
      selfMemberDid: permanentChannelDid,
      message: groupMemberInaugurationMessage,
    );

    await _groupRepository.createGroup(updatedGroup);
    await _groupRepository.removeGroup(group);

    final finalisedConnection = connection.groupFinalise(
      groupId: updatedGroup.id,
      groupDid: updatedGroup.did,
      seqNo: event.startSeqNo,
      notificationToken: notificationToken,
    );

    await connectionOfferRepository.updateConnectionOffer(finalisedConnection);

    await channelService.markGroupChannelInauguratedFromWaitingForApproval(
      channel,
      notificationToken: notificationToken,
      otherPartyPermanentChannelDid: updatedGroup.did,
      sequenceNumber: event.startSeqNo,
    );

    return channel;
  }

  Future<String> _registerNotificationToken(
    String myDid,
    String theirDid,
  ) async {
    logger.info(
      '''Registering notification token for myDid: ${myDid.topAndTail()},
      theirDid: ${theirDid.topAndTail()}''',
      name: '_registerNotificationToken',
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

    logger.info('''Successfully registered notification token:
      ${notificationToken.topAndTail()}''', name: '_registerNotificationToken');

    return notificationToken;
  }

  Future<void> _updateMediatorAcls({
    required DidManager didManager,
    required String permanentChannelDid,
    required String adminDid,
    required String groupDid,
    required String messageFrom,
    required String mediatorDid,
  }) async {
    await Future.wait([
      mediatorService.updateAcl(
        ownerDidManager: didManager,
        mediatorDid: mediatorDid,
        acl: AccessListRemove(
          ownerDid: permanentChannelDid,
          granteeDids: [messageFrom],
        ),
      ),

      // Allow group admin to send messages to member directly for profile
      // requests.
      mediatorService.updateAcl(
        ownerDidManager: didManager,
        mediatorDid: mediatorDid,
        acl: AccessListAdd(
          ownerDid: permanentChannelDid,
          granteeDids: [adminDid],
        ),
      ),

      _allowGroupToSendMessagesToPermanetChannelDid(
        permanentChannelDid: didManager,
        mediatorDid: mediatorDid,
        groupDid: groupDid,
      ),
    ]);
  }

  Future<void> _allowGroupToSendMessagesToPermanetChannelDid({
    required DidManager permanentChannelDid,
    required String mediatorDid,
    required String groupDid,
  }) async {
    final methodName = '_allowGroupToSendMessagesToPermanentChannelDid';
    final permanentChannelDidDocument = await permanentChannelDid
        .getDidDocument();

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

  /// Iterate the member details list and populate/update the
  /// group membership list. Note that this will cause the local
  /// store to reflect the administrator's view of the group membership
  /// list, obviously without the private details of the members.
  Group _updateLocalCopyOfGroupMembers({
    required Group group,
    required String selfMemberDid,
    required GroupMemberInauguration message,
  }) {
    final methodName = '_updateLocalCopyOfGroupMembers';
    logger.info(
      'Updating local copy of group members for group DID: ${group.did.topAndTail()}',
      name: methodName,
    );

    final updatedGroup = group.copyWith(
      id: message.body.groupId,
      did: message.body.groupDid,
      publicKey: message.body.groupPublicKey,
      ownerDid: message.body.adminDids[0],
      created: DateTime.now().toUtc(),
    );

    _updateSelfMemberStatusToApproved(updatedGroup, selfMemberDid);

    for (final member in message.body.members) {
      final localMemberIndex = updatedGroup.members.indexWhere(
        (lm) => lm.did == member.did,
      );

      if (localMemberIndex == -1) {
        updatedGroup.members.add(
          GroupMember(
            did: member.did,
            contactCard: member.contactCard,
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
        card: member.contactCard,
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

  void _updateSelfMemberStatusToApproved(Group group, String selfMemberDid) {
    final selfMember = group.members.firstWhere(
      (member) => member.did == selfMemberDid,
      orElse: () => throw Exception(
        'Self member with DID: ${selfMemberDid.topAndTail()} not found in group members list',
      ),
    );
    selfMember.status = GroupMemberStatus.approved;
  }

  Future<Group> _findGroupByOfferLink(String offerLink) async {
    return await _groupRepository.getGroupByOfferLink(offerLink) ??
        (throw GroupException.notFoundError());
  }
}
