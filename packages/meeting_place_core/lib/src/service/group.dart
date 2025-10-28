import 'dart:convert';

import 'package:didcomm/didcomm.dart';
import 'package:proxy_recrypt/proxy_recrypt.dart' as recrypt;
import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:meeting_place_mediator/meeting_place_mediator.dart';
import '../entity/channel.dart';
import '../entity/connection_offer.dart';
import '../loggers/default_meeting_place_core_sdk_logger.dart';
import '../loggers/meeting_place_core_sdk_logger.dart';
import '../protocol/protocol.dart';
import 'connection_manager/connection_manager.dart';
import '../repository/repository.dart';
import 'connection_offer/connection_offer_exception.dart';
import 'connection_offer/connection_offer_service.dart';
import 'connection_service.dart';
import 'group/group_admin.dart';
import 'group/group_exception.dart';
import 'group_service/accept_group_offer_result.dart';
import '../utils/string.dart';
import 'package:ssi/ssi.dart' show DidDocument, DidManager, DidResolver, Wallet;
import 'package:uuid/uuid.dart';
import '../entity/group.dart';
import '../entity/group_connection_offer.dart';
import '../entity/group_member.dart';
import 'group/group_message.dart' as group_message;

class GroupService {
  GroupService({
    required Wallet wallet,
    required ConnectionManager connectionManager,
    required ConnectionOfferRepository connectionOfferRepository,
    required GroupRepository groupRepository,
    required KeyRepository keyRepository,
    required ChannelRepository channelRepository,
    required ConnectionOfferService offerService,
    required ConnectionService connectionService,
    required ControlPlaneSDK controlPlaneSDK,
    required MeetingPlaceMediatorSDK mediatorSDK,
    required DidResolver didResolver,
    MeetingPlaceCoreSDKLogger? logger,
  })  : _wallet = wallet,
        _connectionManager = connectionManager,
        _connectionOfferRepository = connectionOfferRepository,
        _groupRepository = groupRepository,
        _channelRepository = channelRepository,
        _keyRepository = keyRepository,
        _connectionOfferService = offerService,
        _connectionService = connectionService,
        _controlPlaneSDK = controlPlaneSDK,
        _mediatorSDK = mediatorSDK,
        _didResolver = didResolver,
        _logger =
            logger ?? DefaultMeetingPlaceCoreSDKLogger(className: _className);

  static const String _className = 'GroupService';

  final Wallet _wallet;
  final ConnectionManager _connectionManager;
  final ConnectionOfferRepository _connectionOfferRepository;
  final GroupRepository _groupRepository;
  final ConnectionOfferService _connectionOfferService;
  final ConnectionService _connectionService;
  final ChannelRepository _channelRepository;
  final KeyRepository _keyRepository;
  final DidResolver _didResolver;
  final MeetingPlaceCoreSDKLogger _logger;

  final ControlPlaneSDK _controlPlaneSDK;
  final MeetingPlaceMediatorSDK _mediatorSDK;

  final _recrypt = recrypt.Recrypt();

  Future<
      (
        GroupConnectionOffer connectionOffer,
        DidManager didManager,
        DidManager ownerDid,
      )> createGroup({
    required String offerName,
    required String offerDescription,
    required VCard vCard,
    String? mediatorDid,
    String? customPhrase,
    DateTime? validUntil,
    int? maximumUsage,
    String? metadata,
    String? externalRef,
  }) async {
    final methodName = 'createGroup';
    _logger.info(
      'Started creating group offer for offer: $offerName',
      name: methodName,
    );

    final ownerDid = await _connectionManager.generateDid(_wallet);
    final ownerDidDocument = await ownerDid.getDidDocument();

    final groupKeyPair = _recrypt.generateKeyPair();
    final recryptKeyPair = await generateRecryptKeyPair(ownerDidDocument.id);

    final groupAdmin = createGroupAdmin(
      groupPrivateKey: groupKeyPair.privateKey,
      memberPublicKey: recryptKeyPair.publicKey,
    );

    final oobDidManager = await _connectionManager.generateDid(_wallet);
    final oobDidDoc = await oobDidManager.getDidDocument();

    final oobMessage = OobInvitationMessage.create(from: oobDidDoc.id);

    await _mediatorSDK.updateAcl(
      mediatorDid: mediatorDid,
      ownerDidManager: oobDidManager,
      acl: AclSet.toPublic(ownerDid: oobDidDoc.id),
    );

    final result = await _controlPlaneSDK.execute(
      RegisterOfferGroupCommand(
        offerName: offerName,
        offerDescription: offerDescription,
        vCard: VCardImpl(values: vCard.values),
        device: _controlPlaneSDK.device,
        oobInvitationMessage: oobMessage,
        validUntil: validUntil,
        maximumUsage: maximumUsage,
        customPhrase: customPhrase,
        adminDid: ownerDidDocument.id,
        adminPublicKey: recryptKeyPair.publicKeyToBase64(),
        adminReencryptionKey: groupAdmin.memberReencryptionKey,
        mediatorDid: mediatorDid,
        metadata: metadata,
      ),
    );

    final group = Group(
      id: result.groupId,
      did: result.groupDid,
      offerLink: result.offerLink,
      publicKey: groupKeyPair.publicKeyToBase64(),
      ownerDid: ownerDidDocument.id,
      created: DateTime.now().toUtc(),
      externalRef: externalRef,
      members: [
        GroupMember(
          did: ownerDidDocument.id,
          vCard: vCard,
          dateAdded: DateTime.now().toUtc(),
          publicKey: recryptKeyPair.publicKeyToBase64(),
          status: GroupMemberStatus.approved,
          membershipType: GroupMembershipType.admin,
        ),
      ],
    );

    await _keyRepository.saveKeyPair(
      privateKeyBytes: groupKeyPair.privateKey.toBytes(),
      publicKeyBytes: groupKeyPair.publicKey.point.toBytes(),
      did: result.groupDid,
    );
    await _groupRepository.createGroup(group);

    try {
      await _allowGroupToMessageGroupOwner(
        groupOwnerDid: ownerDid,
        mediatorDid: result.mediatorDid,
        groupDid: result.groupDid,
      );

      final oobDidDoc = await oobDidManager.getDidDocument();
      final connectionOffer = GroupConnectionOffer(
        groupId: result.groupId,
        groupDid: result.groupDid,
        groupOwnerDid: ownerDidDocument.id,
        memberDid: ownerDidDocument.id,
        metadata: metadata,
        offerName: offerName,
        offerLink: result.offerLink,
        offerDescription: offerDescription,
        oobInvitationMessage: toBase64(result.oobInvitationMessage.toJson()),
        mnemonic: result.mnemonic,
        type: ConnectionOfferType.meetingPlaceInvitation,
        expiresAt: result.expiresAt,
        mediatorDid: result.mediatorDid,
        publishOfferDid: oobDidDoc.id,
        vCard: vCard,
        status: ConnectionOfferStatus.published,
        ownedByMe: true,
        externalRef: externalRef,
        createdAt: DateTime.now().toUtc(),
      );

      await _connectionOfferRepository.createConnectionOffer(connectionOffer);

      final channel = Channel(
        offerLink: result.offerLink,
        publishOfferDid: oobDidDoc.id,
        mediatorDid: result.mediatorDid,
        status: ChannelStatus.inaugaurated,
        vCard: vCard,
        type: ChannelType.group,
        permanentChannelDid: ownerDidDocument.id,
        otherPartyPermanentChannelDid: result.groupDid,
        externalRef: externalRef,
      );

      await _channelRepository.createChannel(channel);

      _logger.info(
        'Successfully created group offer: ${result.offerLink}',
        name: methodName,
      );
      return (connectionOffer, oobDidManager, ownerDid);
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to create group offer',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );
      await _controlPlaneSDK.execute(
        DeregisterOfferCommand(
          offerLink: result.offerLink,
          mnemonic: result.mnemonic,
        ),
      );
      Error.throwWithStackTrace(
        ConnectionOfferException.publishOfferError(innerException: e),
        stackTrace,
      );
    }
  }

  GroupAdmin createGroupAdmin({
    required recrypt.PrivateKey groupPrivateKey,
    required recrypt.PublicKey memberPublicKey,
  }) {
    final rkGroupToMember = _recrypt.generateReEncryptionKey(
      groupPrivateKey,
      memberPublicKey,
    );

    return GroupAdmin(
      memberPublicKey: memberPublicKey.toBase64(),
      memberReencryptionKey: rkGroupToMember.toBase64(),
    );
  }

  Future<AcceptGroupOfferResult> acceptGroupOffer({
    required Wallet wallet,
    required GroupConnectionOffer connectionOffer,
    required VCard vCard,
    String? externalRef,
  }) async {
    final methodName = 'acceptGroupOffer';
    _logger.info(
      'Started accepting group offer: ${connectionOffer.offerLink}',
      name: methodName,
    );

    await _connectionOfferService.ensureConnectionOfferIsClaimable(
      connectionOffer.offerLink,
    );

    final acceptOfferDidManager = await _connectionManager.generateDid(wallet);
    final acceptOfferDidDocument = await acceptOfferDidManager.getDidDocument();

    _logger.info(
      'Accept offer DID: ${acceptOfferDidDocument.id.topAndTail()}',
      name: methodName,
    );

    final permanentChannelDidManager = await _connectionManager.generateDid(
      wallet,
    );

    final permanentChannelDidDocument =
        await permanentChannelDidManager.getDidDocument();

    _logger.info(
      'Permanent channel DID: ${permanentChannelDidDocument.id.topAndTail()}',
      name: methodName,
    );

    final result = await _controlPlaneSDK.execute(
      AcceptOfferGroupCommand(
        mnemonic: connectionOffer.mnemonic,
        device: _controlPlaneSDK.device,
        offerLink: connectionOffer.offerLink,
        vCard: VCardImpl(values: vCard.values),
        acceptOfferDid: acceptOfferDidDocument.id,
      ),
    );

    try {
      final invitationMessage = OobInvitationMessage.fromBase64(
        result.didcommMessage,
        {'thid': result.offerLink},
      );

      final keyPair = await generateRecryptKeyPair(
        permanentChannelDidDocument.id,
      );

      // TODO: Is this still required?
      //
      // We use a placeholder ID for the group until we know the real one.
      // These will be updated during `GroupMembershipFinalised`.
      // Using uuid will prevent it from being overwritten when being stored in
      // Hive box as the `group.groupDid` is used as the key, it should be
      // unique per transaction.
      final placeholderId = const Uuid().v4();
      final memberPublicKeyBase64 = keyPair.publicKey.toBase64();

      final group = Group(
        id: placeholderId,
        did: placeholderId,
        offerLink: result.offerLink,
        created: DateTime.now().toUtc(),
        externalRef: externalRef,
        members: [
          GroupMember(
            did: permanentChannelDidDocument.id,
            dateAdded: DateTime.now().toUtc(),
            publicKey: memberPublicKeyBase64,
            status: GroupMemberStatus.pendingApproval,
            membershipType: GroupMembershipType.member,
            vCard: vCard,
          ),
        ],
      );

      await _groupRepository.createGroup(group);

      await sendAcceptInvitationGroupToMediator(
        senderDid: acceptOfferDidManager,
        mediatorDid: result.mediatorDid,
        permanentChannelDid: permanentChannelDidManager,
        invitationMessage: invitationMessage,
        groupMemberPublicKey: memberPublicKeyBase64,
        vCard: vCard,
      );

      final channel = Channel(
        offerLink: connectionOffer.offerLink,
        publishOfferDid: connectionOffer.publishOfferDid,
        permanentChannelDid: permanentChannelDidDocument.id,
        acceptOfferDid: acceptOfferDidDocument.id,
        mediatorDid: connectionOffer.mediatorDid,
        status: ChannelStatus.waitingForApproval,
        type: ChannelType.group,
        vCard: vCard,
        otherPartyVCard: connectionOffer.vCard,
        externalRef: externalRef,
      );

      await _channelRepository.createChannel(channel);

      final acceptedConnectionOffer = connectionOffer.acceptGroupOffer(
        groupId: group.id,
        memberDid: permanentChannelDidDocument.id,
        acceptOfferDid: acceptOfferDidDocument.id,
        permanentChannelDid: permanentChannelDidDocument.id,
        vCard: vCard,
        externalRef: externalRef,
        createdAt: DateTime.now().toUtc(),
      );

      await _connectionOfferRepository.createConnectionOffer(
        acceptedConnectionOffer,
      );

      _logger.info(
        'Successfully accepted group offer: ${connectionOffer.offerLink}',
        name: methodName,
      );
      return AcceptGroupOfferResult(
        connectionOffer: acceptedConnectionOffer,
        acceptOfferDid: acceptOfferDidManager,
        permanentChannelDid: permanentChannelDidManager,
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to accept group offer',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );
      rethrow;
    }
  }

  Future<recrypt.KeyPair> generateRecryptKeyPair(String did) async {
    final recryptKeyPair = _recrypt.generateKeyPair();

    await _keyRepository.saveKeyPair(
      privateKeyBytes: recryptKeyPair.privateKey.toBytes(),
      publicKeyBytes: recryptKeyPair.publicKey.point.toBytes(),
      did: did,
    );

    return recryptKeyPair;
  }

  Future<void> sendAcceptInvitationGroupToMediator({
    required DidManager senderDid,
    required DidManager permanentChannelDid,
    required OobInvitationMessage invitationMessage,
    required String mediatorDid,
    required String groupMemberPublicKey,
    VCard? vCard,
  }) async {
    final methodName = 'sendAcceptInvitationGroupToMediator';
    _logger.info(
      'Started sending accept invitation to mediator: ${mediatorDid.topAndTail()}',
      name: methodName,
    );

    final recipientDid = invitationMessage.from;

    final senderDidDocument = await senderDid.getDidDocument();
    final permanentChannelDidDocument =
        await permanentChannelDid.getDidDocument();

    final recipientDidDocument = await _didResolver.resolveDid(recipientDid);

    await _mediatorSDK.updateAcl(
      ownerDidManager: permanentChannelDid,
      mediatorDid: mediatorDid,
      acl: AccessListAdd(
        ownerDid: permanentChannelDidDocument.id,
        granteeDids: [recipientDid],
      ),
    );

    final connectionSetupMessage = ConnectionSetupGroup.create(
      from: senderDidDocument.id,
      to: [recipientDid],
      parentThreadId: invitationMessage.id,
      permanentChannelDid: permanentChannelDidDocument.id,
      memberPublicKey: groupMemberPublicKey,
      vCard: vCard,
    );

    await _mediatorSDK.sendMessage(
      connectionSetupMessage,
      senderDidManager: senderDid,
      recipientDidDocument: recipientDidDocument,
      mediatorDid: mediatorDid,
      next: recipientDid,
    );
    _logger.info(
      'Successfully sent accept invitation to mediator: ${mediatorDid.topAndTail()}',
      name: methodName,
    );
  }

  Future<void> notifyAcceptance({
    required ConnectionOffer connectionOffer,
    required String senderInfo,
  }) async {
    final methodName = 'notifyAcceptance';
    _logger.info(
      'Started notifying acceptance for offer: ${connectionOffer.offerLink}',
      name: methodName,
    );

    if (!connectionOffer.isAccepted()) {
      _logger.error(
        'Connection offer is not accepted: ${connectionOffer.offerLink}',
        name: methodName,
      );
      throw ConnectionOfferException.notAcceptedError();
    }

    await _controlPlaneSDK.execute(
      NotifyAcceptanceGroupCommand(
        mnemonic: connectionOffer.mnemonic,
        acceptOfferDid: connectionOffer.acceptOfferDid!,
        offerLink: connectionOffer.offerLink,
        senderInfo: senderInfo,
      ),
    );
    _logger.info(
      'Successfully notified acceptance for offer: ${connectionOffer.offerLink}',
      name: methodName,
    );
  }

  Future<Channel> approveMembershipRequest({
    required GroupConnectionOffer connectionOffer,
    required Channel channel,
  }) async {
    final methodName = 'approveMembershipRequest';
    _logger.info(
      'Started approving membership request for offer: ${connectionOffer.offerLink}',
      name: methodName,
    );

    final memberDid = channel.otherPartyPermanentChannelDid;
    if (memberDid == null) {
      _logger.error(
        'Channel does not have other party permanent channel DID',
        name: methodName,
      );
      throw GroupException.memberDidIsNull();
    }

    final group = await _groupRepository.getGroupByOfferLink(
      connectionOffer.offerLink,
    );

    if (group == null) {
      _logger.error(
        'Group not found for offer link: ${connectionOffer.offerLink}',
        name: methodName,
      );
      throw GroupException.notFoundError();
    }

    _logger.info(
      'Group member DIDs: ${group.members.length} members: [${group.members.map((m) => m.did.topAndTail()).join(', ')}], approving member DID: ${memberDid.topAndTail()}',
      name: methodName,
    );
    final member = group.members.firstWhere(
      (m) => m.did == memberDid,
      orElse: () {
        _logger.error(
          'Member DID not found: ${memberDid.topAndTail()}',
          name: methodName,
        );
        throw GroupException.memberDoesNotBelongToGroupError();
      },
    );

    final memberDidDocument = await _didResolver.resolveDid(member.did);
    await _allowMemberToMessageGroupAdmin(group, member, channel.mediatorDid);

    final senderDid = await _connectionManager.getDidManagerForDid(
      _wallet,
      channel.publishOfferDid,
    );

    final reencryptionKey = await generateMemberReEncryptionKey(
      groupDid: group.did,
      member: member,
    );

    await _controlPlaneSDK.execute(
      GroupAddMemberCommand(
        mnemonic: connectionOffer.mnemonic,
        groupId: group.id,
        memberDid: member.did,
        acceptOfferDid: channel.acceptOfferDid!,
        offerLink: connectionOffer.offerLink,
        vCard: channel.otherPartyVCard != null
            ? VCardImpl(values: channel.otherPartyVCard!.values)
            : null,
        publicKey: member.publicKey,
        reencryptionKey: reencryptionKey.toBase64(),
      ),
    );

    final groupMemberInauguration = GroupMemberInauguration.create(
      from: channel.publishOfferDid,
      to: [memberDid],
      memberDid: memberDid,
      groupDid: group.did,
      groupId: group.id,
      adminDids: [group.ownerDid!],
      groupPublicKey: group.publicKey!,
      vCard: VCard(
        values: {
          'n': {'given': connectionOffer.offerName},
        },
      ),
      members: group.members
          .where((member) => member.status == GroupMemberStatus.approved)
          .map(
            (member) => GroupMemberInaugurationMember(
              did: member.did,
              vCard: member.vCard,
              status: member.status.name,
              publicKey: member.publicKey,
              membershipType: member.membershipType.name,
            ),
          )
          .toList(),
    );

    await _mediatorSDK.sendMessage(
      groupMemberInauguration,
      senderDidManager: senderDid,
      recipientDidDocument: memberDidDocument,
      mediatorDid: channel.mediatorDid,
    );

    group.approveMember(member);
    await _groupRepository.updateGroup(group);

    _logger.info(
      'Successfully approved membership request for offer: ${connectionOffer.offerLink}',
      name: methodName,
    );

    return channel;
  }

  Future<Group> rejectMembershipRequest(Channel channel) async {
    final methodName = 'rejectMembershipRequest';
    _logger.info(
      'Rejecting membership request for offer: ${channel.offerLink}',
      name: methodName,
    );

    final group = await _groupRepository.getGroupByOfferLink(channel.offerLink);
    if (group == null) {
      _logger.error(
        'Group not found for offer link: ${channel.offerLink}',
        name: methodName,
      );
      throw GroupException.notFoundError();
    }

    group.members.removeWhere(
      (member) => member.did == channel.otherPartyPermanentChannelDid,
    );

    await _groupRepository.updateGroup(group);

    _logger.info(
      'Successfully rejected membership request for offer: ${channel.offerLink}',
      name: methodName,
    );
    return group;
  }

  Future<Group?> getGroupByOfferLink(String offerLink) {
    return _groupRepository.getGroupByOfferLink(offerLink);
  }

  Future<Group?> getGroupById(String groupId) {
    return _groupRepository.getGroupById(groupId);
  }

  Future<void> sendMessage(
    PlainTextMessage message, {
    required DidManager senderDid,
    required DidDocument groupDidDocument,
    bool increaseSequenceNumber = true,
    bool notify = true,
    bool ephemeral = false,
    int? forwardExpiryInSeconds,
  }) async {
    final methodName = 'sendMessage';
    _logger.info(
      'Sending message to group DID: ${groupDidDocument.id.topAndTail()}',
      name: methodName,
    );

    final channel = await _channelRepository
        .findChannelByOtherPartyPermanentChannelDid(groupDidDocument.id);

    if (channel == null) {
      _logger.error(
        'Channel not found for group DID: ${groupDidDocument.id.topAndTail()}',
        name: methodName,
      );
      throw GroupException.channelDoesNotExistError();
    }

    final group = await getGroupByOfferLink(channel.offerLink);
    if (group == null) throw GroupException.notFoundError();

    final encryptedMessage = group_message.GroupMessage.encrypt(
      message,
      publicKeyBytes: recrypt.PublicKey.fromBase64(
        group.publicKey!,
      ).point.toBytes(),
    );

    await _controlPlaneSDK.execute(
      GroupSendMessageCommand(
        offerLink: channel.offerLink,
        fromDid: message.from!,
        groupDid: groupDidDocument.id,
        messageBase64: _encodeEncryptedMessagePayload(encryptedMessage),
        increaseSequenceNumber: increaseSequenceNumber,
        notify: notify,
        ephemeral: ephemeral,
        forwardExpiryInSeconds: forwardExpiryInSeconds,
      ),
    );
    _logger.info(
      'Successfully sent message to group DID: ${groupDidDocument.id.topAndTail()}',
      name: methodName,
    );
  }

  Future<void> _allowMemberToMessageGroupAdmin(
    Group group,
    GroupMember member,
    String mediatorDid,
  ) async {
    final ownerDid = await _connectionManager.getDidManagerForDid(
      _wallet,
      group.ownerDid!,
    );

    await _mediatorSDK.updateAcl(
      ownerDidManager: ownerDid,
      acl: AccessListAdd(ownerDid: group.ownerDid!, granteeDids: [member.did]),
      mediatorDid: mediatorDid,
    );
  }

  Future<void> _allowGroupToMessageGroupOwner({
    required DidManager groupOwnerDid,
    required String mediatorDid,
    required String groupDid,
  }) async {
    final groupOwnerDidDocument = await groupOwnerDid.getDidDocument();

    return _mediatorSDK.updateAcl(
      ownerDidManager: groupOwnerDid,
      mediatorDid: mediatorDid,
      acl: AccessListAdd(
        ownerDid: groupOwnerDidDocument.id,
        granteeDids: [groupDid],
      ),
    );
  }

  Future<void> _removePermissionToGetMessagesFromGroup({
    required DidManager memberDid,
    required String mediatorDid,
    required String groupDid,
  }) async {
    final memberDidDocument = await memberDid.getDidDocument();

    return _mediatorSDK.updateAcl(
      ownerDidManager: memberDid,
      mediatorDid: mediatorDid,
      acl: AccessListRemove(
        ownerDid: memberDidDocument.id,
        granteeDids: [groupDid],
      ),
    );
  }

  Future<void> leaveGroup(Channel channel) async {
    final methodName = 'leaveGroup';
    _logger.info(
      'Leaving group for channel with offer link: ${channel.offerLink}',
      name: methodName,
    );

    final memberDid = channel.permanentChannelDid!;
    final group = await _groupRepository.getGroupByOfferLink(channel.offerLink);
    if (group == null) {
      _logger.warning(
        'Group not found for offer link: ${channel.offerLink}',
        name: methodName,
      );
      return;
    }

    final memberDidManager =
        await _connectionManager.getDidManagerForDid(_wallet, memberDid);

    if (group.isMemberOfTypeAdmin(memberDid)) {
      await _leaveGroupAsAdmin(group, memberDid);
    } else {
      await _leaveGroupAsMember(group: group, memberDid: memberDid);
    }

    if (channel.notificationToken != null) {
      _logger.info(
        'Deregistering notification token for channel with offer link: ${channel.offerLink}',
        name: methodName,
      );
      await _controlPlaneSDK.execute(
        DeregisterNotificationCommand(
          notificationToken: channel.notificationToken!,
        ),
      );
    }

    final connectionOffer = await _connectionOfferRepository
        .getConnectionOfferByOfferLink(channel.offerLink);
    if (connectionOffer != null) {
      await _connectionService.markConnectionOfferAsDeleted(connectionOffer);
    }

    await _channelRepository.deleteChannel(channel);
    await _removePermissionToGetMessagesFromGroup(
      groupDid: group.did,
      mediatorDid: channel.mediatorDid,
      memberDid: memberDidManager,
    );

    await _groupRepository.removeGroup(group);
    _logger.info(
      'Successfully left group for channel with offer link: ${channel.offerLink}',
      name: methodName,
    );
  }

  Future<void> delete(String groupId) async {
    final methodName = 'delete';
    _logger.info('Deleting group with ID: $groupId', name: methodName);

    final group = await _groupRepository.getGroupById(groupId);
    if (group == null) {
      _logger.warning(
        'Group does not exist, skip deletion with ID: $groupId',
        name: methodName,
      );
      return;
    }
    await _groupRepository.removeGroup(group);
    _logger.info(
      'Successfully deleted group with ID: $groupId',
      name: methodName,
    );
  }

  Future<void> _leaveGroupAsAdmin(Group group, String memberDid) async {
    final encryptedMessage = group_message.GroupMessage.encrypt(
      GroupDelete.create(groupId: group.id),
      publicKeyBytes: recrypt.PublicKey.fromBase64(
        group.publicKey!,
      ).point.toBytes(),
    );

    await _controlPlaneSDK.execute(
      GroupDeleteCommand(
        groupId: group.id,
        messageBase64: _encodeEncryptedMessagePayload(encryptedMessage),
      ),
    );
  }

  Future<void> _leaveGroupAsMember({
    required Group group,
    required String memberDid,
  }) async {
    final encryptedMessage = group_message.GroupMessage.encrypt(
      GroupMemberDeregistered.create(groupId: group.id, memberDid: memberDid),
      publicKeyBytes: recrypt.PublicKey.fromBase64(
        group.publicKey!,
      ).point.toBytes(),
    );

    await _controlPlaneSDK.execute(
      GroupDeregisterMemberCommand(
        groupId: group.id,
        memberId: memberDid,
        messageBase64: _encodeEncryptedMessagePayload(encryptedMessage),
      ),
    );
  }

  String _encodeEncryptedMessagePayload(
    group_message.EncryptedGroupMessage message,
  ) {
    return base64.encode(
      utf8.encode(
        jsonEncode({
          'ciphertext': base64.encode(message.ciphertextBytes),
          'capsule': message.capsule.toBase64(),
          'iv': base64.encode(message.initializationVector),
          'authenticationTag': base64.encode(message.authenticationTag),
        }),
      ),
    );
  }

  Future<recrypt.ReEncryptionKey> generateMemberReEncryptionKey({
    required String groupDid,
    required GroupMember member,
  }) async {
    final storedKeyPair = await _keyRepository.getKeyPair(groupDid);
    final privateKey = recrypt.PrivateKey.fromBase64(
      base64.encode(storedKeyPair!.privateKeyBytes),
    );

    return recrypt.Recrypt().generateReEncryptionKey(
      privateKey,
      recrypt.PublicKey.fromBase64(member.publicKey),
    );
  }
}
