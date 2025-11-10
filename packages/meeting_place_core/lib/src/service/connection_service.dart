import 'package:didcomm/didcomm.dart';
import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:meeting_place_mediator/meeting_place_mediator.dart';
import '../entity/channel.dart';
import '../entity/connection_offer.dart';
import '../entity/group_connection_offer.dart';
import '../loggers/default_meeting_place_core_sdk_logger.dart';
import '../loggers/meeting_place_core_sdk_logger.dart';
import '../protocol/protocol.dart';
import '../repository/repository.dart';
import 'connection_manager/connection_manager.dart';
import '../sdk/results/results.dart' hide AcceptOfferResult;
import 'connection_offer/connection_offer_exception.dart';
import 'connection_offer/connection_offer_service.dart';
import '../utils/string.dart';
import 'package:ssi/ssi.dart';
import 'connection_offer/offer_already_claimed_exception.dart';
import 'connection_offer/offer_owner_exception.dart';
import 'connection_service/accept_offer_result.dart';

class FindOfferException implements Exception {
  FindOfferException(this.message);
  final String message;

  @override
  String toString() => 'FindOfferException: $message)';
}

typedef FindOfferErrorCodes = FindOfferResultErrorCode;

// TODO: combine with connection offer service
class ConnectionService {
  ConnectionService({
    required ConnectionManager connectionManager,
    required ConnectionOfferRepository connectionOfferRepository,
    required ChannelRepository channelRepository,
    required ControlPlaneSDK controlPlaneSDK,
    required MeetingPlaceMediatorSDK mediatorSDK,
    required ConnectionOfferService offerService,
    required DidResolver didResolver,
    MeetingPlaceCoreSDKLogger? logger,
  })  : _connectionManager = connectionManager,
        _channelRepository = channelRepository,
        _connectionOfferRepository = connectionOfferRepository,
        _mediatorSDK = mediatorSDK,
        _controlPlaneSDK = controlPlaneSDK,
        _connectionOfferService = offerService,
        _didResolver = didResolver,
        _logger =
            logger ?? DefaultMeetingPlaceCoreSDKLogger(className: _className);

  static const String _className = 'ConnectionService';

  final ConnectionManager _connectionManager;
  final ConnectionOfferRepository _connectionOfferRepository;
  final ConnectionOfferService _connectionOfferService;
  final ChannelRepository _channelRepository;
  final MeetingPlaceMediatorSDK _mediatorSDK;
  final ControlPlaneSDK _controlPlaneSDK;
  final DidResolver _didResolver;
  final MeetingPlaceCoreSDKLogger _logger;

  Future<(ConnectionOffer? connectionOffer, FindOfferErrorCodes? errorCode)>
      findOffer({required String mnemonic}) async {
    final methodName = 'findOffer';
    _logger.info('Finding offer with mnemonic: $mnemonic', name: methodName);

    final response = await _controlPlaneSDK.execute(
      QueryOfferCommand(mnemonic: mnemonic),
    );

    if (response is NullQueryOfferCommandOutput) {
      _logger.error('Connection offer not found', name: methodName);
      throw ConnectionOfferException.offerNotFoundError();
    }

    if (response is LimitExceededQueryOfferCommandOutput) {
      _logger.error('Offer query limit exceeded', name: methodName);
      throw ConnectionOfferException.limitExceeded();
    }

    if (response is ExpiredQueryOfferCommandOutput) {
      _logger.error('Connection offer has expired', name: methodName);
      throw ConnectionOfferException.expired();
    }

    FindOfferErrorCodes? errorCode;
    bool ownedByMe = false;

    final queryOfferResult = response as SuccessQueryOfferCommandOutput;

    try {
      await _connectionOfferService.ensureConnectionOfferIsClaimable(
        queryOfferResult.offerLink,
      );
    } on OfferOwnerException {
      _logger.error('Offer is owned by the claiming party', name: methodName);
      errorCode = FindOfferErrorCodes.offerOwnedByClaimingParty;
      ownedByMe = true;
    } on OfferAlreadyClaimedException {
      _logger.error(
        'Offer is already claimed by the claiming party',
        name: methodName,
      );
      errorCode = FindOfferErrorCodes.offerAlreadyClaimedByParty;
    }

    if (!queryOfferResult.isGroupInvitation) {
      final connectionOffer = ConnectionOffer(
        offerName: queryOfferResult.offerName,
        offerLink: queryOfferResult.offerLink,
        offerDescription: queryOfferResult.offerDescription,
        mnemonic: queryOfferResult.mnemonic,
        vCard: VCard(values: queryOfferResult.vCard.values),
        expiresAt: queryOfferResult.expiresAt,
        publishOfferDid: queryOfferResult.didcommMessage.from,
        mediatorDid: queryOfferResult.mediatorDid,
        oobInvitationMessage: queryOfferResult.didcommMessage.toBase64(),
        maximumUsage: queryOfferResult.maximumUsage,
        type: queryOfferResult.isOutreachInvitation
            ? ConnectionOfferType.meetingPlaceOutreachInvitation
            : ConnectionOfferType.meetingPlaceInvitation,
        status: ConnectionOfferStatus.published,
        ownedByMe: ownedByMe,
        createdAt: DateTime.now().toUtc(),
      );

      _logger.info('''
        Individual connection offer found:
          name=${queryOfferResult.offerName},
          link=${queryOfferResult.offerLink},
          mnemonic=${queryOfferResult.mnemonic},
          status=${queryOfferResult.status},
          ownedByMe=$ownedByMe
      ''', name: methodName);
      return (connectionOffer, errorCode);
    } else {
      final groupConnectionOffer = GroupConnectionOffer(
        groupId: queryOfferResult.groupId!,
        groupDid: queryOfferResult.groupDid!,
        offerName: queryOfferResult.offerName,
        offerLink: queryOfferResult.offerLink,
        offerDescription: queryOfferResult.offerDescription,
        mnemonic: queryOfferResult.mnemonic,
        vCard: VCard(values: queryOfferResult.vCard.values),
        expiresAt: queryOfferResult.expiresAt,
        publishOfferDid: queryOfferResult.didcommMessage.from,
        mediatorDid: queryOfferResult.mediatorDid,
        oobInvitationMessage: queryOfferResult.didcommMessage.toBase64(),
        maximumUsage: queryOfferResult.maximumUsage,
        type: ConnectionOfferType.meetingPlaceInvitation,
        status: ConnectionOfferStatus.published,
        ownedByMe: ownedByMe,
        createdAt: DateTime.now().toUtc(),
      );

      _logger.info('''
        Group connection offer found:
          groupId=${queryOfferResult.groupId},
          groupDid=${queryOfferResult.groupDid},
          name=${queryOfferResult.offerName},
          link=${queryOfferResult.offerLink},
          mnemonic=${queryOfferResult.mnemonic},
          status=${queryOfferResult.status},
          ownedByMe=$ownedByMe
      ''', name: methodName);
      return (groupConnectionOffer, errorCode);
    }
  }

  Future<(ConnectionOffer, DidManager)> publishOffer({
    required String offerName,
    required String offerDescription,
    required VCard vCard,
    required Wallet wallet,
    required ConnectionOfferType type,
    String? customPhrase,
    DateTime? validUntil,
    int? maximumUsage,
    String? mediatorDid,
    String? externalRef,
  }) async {
    final methodName = 'publishOffer';
    _logger.info('Publishing connection offer: $offerName', name: methodName);

    final oobDidManager = await _connectionManager.generateDid(wallet);
    final oobDidDoc = await oobDidManager.getDidDocument();

    final oobMessage = OobInvitationMessage.create(from: oobDidDoc.id);

    await _mediatorSDK.updateAcl(
      mediatorDid: mediatorDid,
      ownerDidManager: oobDidManager,
      acl: AclSet.toPublic(ownerDid: oobDidDoc.id),
    );

    final registerOfferOutput = await _controlPlaneSDK.execute(
      RegisterOfferCommand(
        offerName: offerName,
        offerDescription: offerDescription,
        type: type == ConnectionOfferType.meetingPlaceOutreachInvitation
            ? OfferType.outreachInvitation
            : OfferType.invitation,
        oobInvitationMessage: oobMessage,
        vCard: VCardImpl(values: vCard.values),
        device: _controlPlaneSDK.device,
        customPhrase: customPhrase,
        validUntil: validUntil,
        maximumUsage: maximumUsage,
        mediatorDid: mediatorDid,
      ),
    );

    try {
      final didDocument = await oobDidManager.getDidDocument();
      final connectionOffer = ConnectionOffer(
        offerName: registerOfferOutput.offerName,
        offerLink: registerOfferOutput.offerLink,
        offerDescription: registerOfferOutput.offerDescription,
        mnemonic: registerOfferOutput.mnemonic,
        type: type,
        expiresAt: registerOfferOutput.expiresAt,
        mediatorDid: registerOfferOutput.mediatorDid,
        oobInvitationMessage: toBase64(
          registerOfferOutput.didcommMessage.toJson(),
        ),
        publishOfferDid: didDocument.id,
        maximumUsage: registerOfferOutput.maximumUsage,
        vCard: vCard,
        status: ConnectionOfferStatus.published,
        ownedByMe: true,
        externalRef: externalRef,
        createdAt: DateTime.now().toUtc(),
      );

      await _connectionOfferRepository.createConnectionOffer(connectionOffer);
      _logger.info('Connection offer published: $offerName', name: methodName);
      return (connectionOffer, oobDidManager);
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to publish connection offer',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );
      await _controlPlaneSDK.execute(
        DeregisterOfferCommand(
          offerLink: registerOfferOutput.offerLink,
          mnemonic: registerOfferOutput.mnemonic,
        ),
      );
      Error.throwWithStackTrace(
        ConnectionOfferException.publishOfferError(innerException: e),
        stackTrace,
      );
    }
  }

  Future<AcceptOfferResult> acceptOffer({
    required Wallet wallet,
    required ConnectionOffer connectionOffer,
    required VCard vCard,
    String? externalRef,
  }) async {
    final methodName = 'acceptOffer';
    _logger.info(
      'Accepting connection offer: ${connectionOffer.offerName}',
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
      AcceptOfferCommand(
        mnemonic: connectionOffer.mnemonic,
        device: _controlPlaneSDK.device,
        offerLink: connectionOffer.offerLink,
        acceptOfferDid: acceptOfferDidDocument.id,
        vCard: VCardImpl(values: vCard.values),
      ),
    );

    final invitationMessage = OobInvitationMessage.fromBase64(
      result.didcommMessage,
      {'thid': result.offerLink},
    );

    await sendAcceptOfferToMediator(
      acceptOfferDid: acceptOfferDidManager,
      permanentChannelDidDocument: permanentChannelDidDocument,
      invitationMessage: invitationMessage,
      mediatorDid: result.mediatorDid,
      acceptVCard: vCard,
    );

    final acceptedConnectionOffer = await _acceptConnectionOffer(
      connectionOffer,
      acceptOfferDidDocument: acceptOfferDidDocument,
      permanentChannelDidDocument: permanentChannelDidDocument,
      vCard: vCard,
      externalRef: externalRef,
    );

    final channel = Channel.individualFromAcceptedConnectionOffer(
      acceptedConnectionOffer,
      permanentChannelDid: permanentChannelDidDocument.id,
      acceptOfferDid: acceptOfferDidDocument.id,
      vCard: vCard,
      externalRef: externalRef,
    );

    await _channelRepository.createChannel(channel);
    return AcceptOfferResult(
      connectionOffer: acceptedConnectionOffer,
      channel: channel,
      acceptOfferDid: acceptOfferDidManager,
      permanentChannelDid: permanentChannelDidManager,
    );
  }

  Future<ConnectionOffer> _acceptConnectionOffer(
    ConnectionOffer connectionOffer, {
    required DidDocument acceptOfferDidDocument,
    required DidDocument permanentChannelDidDocument,
    required VCard vCard,
    String? externalRef,
  }) async {
    final existingConnectionOffer = await _connectionOfferRepository
        .getConnectionOfferByOfferLink(connectionOffer.offerLink);

    if (existingConnectionOffer != null) {
      final acceptedConnectionOffer = existingConnectionOffer.accept(
        acceptOfferDid: acceptOfferDidDocument.id,
        permanentChannelDid: permanentChannelDidDocument.id,
        vCard: vCard,
        externalRef: externalRef,
        createdAt: DateTime.now().toUtc(),
      );

      await _connectionOfferRepository.updateConnectionOffer(
        acceptedConnectionOffer,
      );

      return acceptedConnectionOffer;
    }

    final acceptedConnectionOffer = connectionOffer.accept(
      acceptOfferDid: acceptOfferDidDocument.id,
      permanentChannelDid: permanentChannelDidDocument.id,
      vCard: vCard,
      externalRef: externalRef,
      createdAt: DateTime.now().toUtc(),
    );

    await _connectionOfferRepository.createConnectionOffer(
      acceptedConnectionOffer,
    );

    return acceptedConnectionOffer;
  }

  Future<void> sendAcceptOfferToMediator({
    required DidManager acceptOfferDid,
    required DidDocument permanentChannelDidDocument,
    required PlainTextMessage invitationMessage,
    String? mediatorDid,
    VCard? acceptVCard,
  }) async {
    final methodName = 'sendAcceptOfferToMediator';
    _logger.info('Sending accept offer to mediator', name: methodName);

    final recipientDid = invitationMessage.from!;
    final recipientDidDocument = await _didResolver.resolveDid(recipientDid);
    final acceptOfferDidDocument = await acceptOfferDid.getDidDocument();

    await _mediatorSDK.updateAcl(
      ownerDidManager: acceptOfferDid,
      mediatorDid: mediatorDid,
      acl: AccessListAdd(
        ownerDid: acceptOfferDidDocument.id,
        granteeDids: [recipientDid],
      ),
    );

    final connectionSetupMessage = ConnectionSetup.create(
      from: acceptOfferDidDocument.id,
      to: [recipientDid],
      parentThreadId: invitationMessage.id,
      permanentChannelDid: permanentChannelDidDocument.id,
      vCard: acceptVCard,
    );

    await _mediatorSDK.sendMessage(
      connectionSetupMessage,
      senderDidManager: acceptOfferDid,
      recipientDidDocument: recipientDidDocument,
      mediatorDid: mediatorDid,
      next: recipientDid,
    );

    _logger.info('Accept offer sent to mediator', name: methodName);
  }

  Future<void> notifyAcceptance({
    required ConnectionOffer connectionOffer,
    required String senderInfo,
  }) async {
    final methodName = 'notifyAcceptance';
    _logger.info(
      'Notifying acceptance for offer: ${connectionOffer.offerName}',
      name: methodName,
    );

    final acceptOfferDid = connectionOffer.acceptOfferDid;
    if (!connectionOffer.isAccepted() || acceptOfferDid == null) {
      _logger.error(
        'Connection offer is not accepted or acceptOfferDid is null',
        name: methodName,
      );
      throw ConnectionOfferException.notAcceptedError();
    }

    await _controlPlaneSDK.execute(
      NotifyAcceptanceCommand(
        mnemonic: connectionOffer.mnemonic,
        offerLink: connectionOffer.offerLink,
        acceptOfferDid: acceptOfferDid,
        senderInfo: senderInfo,
      ),
    );

    _logger.info(
      'Acceptance notified for offer: ${connectionOffer.offerName}',
      name: methodName,
    );
  }

  Future<Channel> approveConnectionRequest({
    required Wallet wallet,
    required ConnectionOffer connectionOffer,
    required Channel channel,
  }) async {
    final methodName = 'approveConnectionRequest';
    _logger.info(
      'Approving connection request for offer: ${connectionOffer.offerName}',
      name: methodName,
    );

    final acceptOfferDid = channel.acceptOfferDid;
    final otherPartyPermanentChannelDid = channel.otherPartyPermanentChannelDid;

    if (connectionOffer.isFinalised()) {
      _logger.error('Connection offer is already finalised', name: methodName);
      throw ConnectionOfferException.alreadyFinalised();
    }

    if (acceptOfferDid == null) {
      _logger.error('Accept offer DID is null', name: methodName);
      throw ConnectionOfferException.notAcceptedError();
    }

    if (otherPartyPermanentChannelDid == null) {
      _logger.error(
        'Other party permanent channel DID is null',
        name: methodName,
      );
      throw ConnectionOfferException.permanentChannelDidError();
    }

    final publishOfferDid = await _connectionManager.getDidManagerForDid(
      wallet,
      channel.publishOfferDid,
    );

    final permanentChannelDid = await _connectionManager.generateDid(wallet);
    final permanentChannelDidDocument =
        await permanentChannelDid.getDidDocument();

    await sendConnectionRequestApprovalToMediator(
      offerPublishedDid: publishOfferDid,
      permanentChannelDid: permanentChannelDid,
      otherPartyPermanentChannelDid: otherPartyPermanentChannelDid,
      otherPartyAcceptOfferDid: acceptOfferDid,
      outboundMessageId: connectionOffer.offerLink,
      mediatorDid: connectionOffer.mediatorDid,
      vCard: channel.vCard,
    );

    final finaliseAcceptanceOutput = await _controlPlaneSDK.execute(
      FinaliseAcceptanceCommand(
        mnemonic: connectionOffer.mnemonic,
        device: _controlPlaneSDK.device,
        offerLink: connectionOffer.offerLink,
        offerPublishedDid: channel.publishOfferDid,
        otherPartyAcceptOfferDid: channel.acceptOfferDid!,
        otherPartyPermanentChannelDid: channel.otherPartyPermanentChannelDid!,
        vCard: channel.vCard != null
            ? VCardImpl(values: channel.vCard!.values)
            : null,
      ),
    );

    final finalisedConnection = connectionOffer.finalise(
      permanentChannelDid: permanentChannelDidDocument.id,
      otherPartyPermanentChannelDid: otherPartyPermanentChannelDid,
    );
    await _connectionOfferRepository.updateConnectionOffer(finalisedConnection);

    channel.permanentChannelDid = permanentChannelDidDocument.id;
    channel.otherPartyPermanentChannelDid = otherPartyPermanentChannelDid;
    channel.notificationToken = finaliseAcceptanceOutput.notificationToken;
    channel.status = ChannelStatus.approved;
    await _channelRepository.updateChannel(channel);

    _logger.info(
      'Connection request approved for offer: ${connectionOffer.offerName}',
      name: methodName,
    );

    return channel;
  }

  Future<void> sendConnectionRequestApprovalToMediator({
    required DidManager offerPublishedDid,
    required DidManager permanentChannelDid,
    required String otherPartyPermanentChannelDid,
    required String otherPartyAcceptOfferDid,
    required String outboundMessageId,
    required String mediatorDid,
    VCard? vCard,
  }) async {
    final methodName = 'sendConnectionRequestApprovalToMediator';
    _logger.info(
      'Sending connection request approval to mediator',
      name: methodName,
    );

    final permanentChannelDidDocument =
        await permanentChannelDid.getDidDocument();

    final offerPublishedDidDocument = await offerPublishedDid.getDidDocument();

    await _mediatorSDK.updateAcl(
      ownerDidManager: permanentChannelDid,
      mediatorDid: mediatorDid,
      acl: AccessListAdd(
        ownerDid: permanentChannelDidDocument.id,
        granteeDids: [otherPartyPermanentChannelDid, otherPartyAcceptOfferDid],
      ),
    );

    final connectionInvitationAcceptedMessage = ConnectionAccepted.create(
      from: offerPublishedDidDocument.id,
      to: [otherPartyAcceptOfferDid],
      parentThreadId: outboundMessageId,
      permanentChannelDid: permanentChannelDidDocument.id,
      vCard: vCard,
    );

    final recipientDidDocument = await _didResolver.resolveDid(
      otherPartyAcceptOfferDid,
    );

    await _mediatorSDK.sendMessage(
      connectionInvitationAcceptedMessage,
      senderDidManager: offerPublishedDid,
      recipientDidDocument: recipientDidDocument,
      mediatorDid: mediatorDid,
      next: otherPartyAcceptOfferDid,
    );

    _logger.info(
      'Connection request approval sent to mediator',
      name: methodName,
    );
  }

  Future<void> unlink({
    required Wallet wallet,
    required Channel channel,
  }) async {
    final connectionOffer = await _connectionOfferRepository
        .getConnectionOfferByOfferLink(channel.offerLink);

    final networkRequests = <Future<dynamic>>[];
    if (channel.notificationToken != null) {
      networkRequests.add(
        _controlPlaneSDK.execute(
          DeregisterNotificationCommand(
            notificationToken: channel.notificationToken!,
          ),
        ),
      );
    }

    networkRequests.add(
      _removePermissionToGetMessagesFromChannel(
        wallet: wallet,
        channel: channel,
      ),
    );

    await Future.wait(networkRequests);
    await _channelRepository.deleteChannel(channel);
    if (connectionOffer != null && !connectionOffer.ownedByMe) {
      await _connectionOfferService.markAsDeleted(connectionOffer);
    }
  }

  Future<ConnectionOffer> markConnectionOfferAsDeleted(
    ConnectionOffer connectionOffer,
  ) async {
    final methodName = 'markConnectionOfferAsDeleted';
    _logger.info(
      'Marking connection offer as deleted: ${connectionOffer.offerName}',
      name: methodName,
    );

    if (connectionOffer.isDeleted()) {
      _logger.warning(
        'Connection offer already marked as deleted: ${connectionOffer.offerName}',
        name: methodName,
      );
      return Future.value(connectionOffer);
    }
    await _deregisterOfferFromControlPlane(connectionOffer);

    final deletedConnectionOffer = connectionOffer.markAsDeleted();
    await _connectionOfferRepository.updateConnectionOffer(
      deletedConnectionOffer,
    );

    _logger.info(
      'Connection offer marked as deleted: ${connectionOffer.offerName}',
      name: methodName,
    );
    return deletedConnectionOffer;
  }

  Future<void> deleteConnectionOffer(ConnectionOffer connectionOffer) async {
    final methodName = 'deleteConnectionOffer';
    _logger.info(
      'Deleting connection offer: ${connectionOffer.offerName}',
      name: methodName,
    );

    final connectionOfferToBeDeleted = await _connectionOfferRepository
        .getConnectionOfferByOfferLink(connectionOffer.offerLink);
    if (connectionOfferToBeDeleted == null) {
      _logger.error(
        'Connection offer does not exist: ${connectionOffer.offerName}',
        name: methodName,
      );
      throw ConnectionOfferException.offerNotFoundError();
    }

    await _deregisterOfferFromControlPlane(connectionOffer);
    _logger.info(
      'Connection offer deleted: ${connectionOffer.offerName}',
      name: methodName,
    );
    return _connectionOfferRepository.deleteConnectionOffer(connectionOffer);
  }

  Future<void> _deregisterOfferFromControlPlane(
    ConnectionOffer connectionOffer,
  ) async {
    final methodName = '_deregisterOfferFromControlPlane';
    _logger.info(
      'Deregistering offer from control plane API: ${connectionOffer.offerName}',
      name: methodName,
    );

    if (!connectionOffer.ownedByMe) {
      _logger.warning(
        'Offer is not owned by me, skipping deregistration: ${connectionOffer.offerName}',
        name: methodName,
      );
      return;
    }

    await _controlPlaneSDK.execute(
      DeregisterOfferCommand(
        offerLink: connectionOffer.offerLink,
        mnemonic: connectionOffer.mnemonic,
      ),
    );

    // TODO: update ACLs to remove public access from offer published DID?
    _logger.info(
      'Offer deregistered from control plane API: ${connectionOffer.offerName}',
      name: methodName,
    );
  }

  Future<void> _removePermissionToGetMessagesFromChannel({
    required Wallet wallet,
    required Channel channel,
  }) async {
    final permanentChannelDid = channel.permanentChannelDid;
    final otherPartyPermanentChannelDid = channel.otherPartyPermanentChannelDid;
    if (permanentChannelDid == null || otherPartyPermanentChannelDid == null) {
      return;
    }

    final didManager = await _connectionManager.getDidManagerForDid(
      wallet,
      channel.permanentChannelDid!,
    );

    return _mediatorSDK.updateAcl(
      ownerDidManager: didManager,
      mediatorDid: channel.mediatorDid,
      acl: AccessListRemove(
        ownerDid: channel.permanentChannelDid!,
        granteeDids: [channel.otherPartyPermanentChannelDid!],
      ),
    );
  }
}
