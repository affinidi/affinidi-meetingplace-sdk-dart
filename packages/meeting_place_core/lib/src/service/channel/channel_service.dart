import '../../entity/entity.dart';
import '../../protocol/protocol.dart';
import '../../repository/repository.dart';
import 'channel_service_exception.dart';

/// Service for managing channels.
class ChannelService {
  /// Creates a new instance of [ChannelService].
  ChannelService({required ChannelRepository channelRepository})
    : _channelRepository = channelRepository;

  /// The repository used for accessing channel data.
  final ChannelRepository _channelRepository;

  /// Finds a channel by its DID, returning null if not found.
  ///
  /// Parameters:
  /// - [did]: The DID of the channel to find.
  ///
  /// Returns [Channel] if found, otherwise null.
  Future<Channel?> findChannelByDidOrNull(String did) {
    return _channelRepository.findChannelByDid(did);
  }

  /// Finds a channel by its DID.
  ///
  /// Parameters:
  /// - [did]: The DID of the channel to find.
  ///
  /// Returns [Channel] if found, otherwise throws a [ChannelServiceException].
  Future<Channel> findChannelByDid(String did) async {
    return await findChannelByDidOrNull(did) ??
        (throw ChannelServiceException.channelNotFound(did: did));
  }

  /// Finds a [Channel] by the DID of the other party's permanent channel,
  /// returning null if not found.
  ///
  /// Parameters:
  /// - [did]: The DID of the other party's permanent channel.
  ///
  /// Returns [Channel] if found, otherwise null.
  Future<Channel?> findChannelByOtherPartyPermanentChannelDidOrNull(
    String did,
  ) {
    return _channelRepository.findChannelByOtherPartyPermanentChannelDid(did);
  }

  /// Finds a [Channel] by the DID of the other party's permanent channel.
  ///
  /// Parameters:
  /// - [did]: The DID of the other party's permanent channel.
  ///
  /// Returns [Channel] if found, otherwise throws a [ChannelServiceException].
  Future<Channel> findChannelByOtherPartyPermanentChannelDid(String did) async {
    return await findChannelByOtherPartyPermanentChannelDidOrNull(did) ??
        (throw ChannelServiceException.channelNotFound(did: did));
  }

  /// Persists a new [Channel].
  ///
  /// Parameters:
  /// - [channel]: The [Channel] to persist.
  ///
  /// Returns a [Future] that completes when the channel is persisted.
  Future<void> persistChannel(Channel channel) {
    return _channelRepository.createChannel(channel);
  }

  /// Updates an existing [Channel].
  ///
  /// Parameters:
  /// - [channel]: The [Channel] to update.
  ///
  /// Returns a [Future] that completes when the channel is updated.
  Future<void> updateChannel(Channel channel) {
    return _channelRepository.updateChannel(channel);
  }

  /// Deletes a [Channel].
  ///
  /// Parameters:
  /// - [channel]: The [Channel] to delete.
  ///
  /// Returns a [Future] that completes when the channel is deleted.
  Future<void> deleteChannel(Channel channel) {
    return _channelRepository.deleteChannel(channel);
  }

  /// Marks a channel as approved for a connection initiator, updating its
  /// permanent channel DID, other party's permanent channel DID, notification
  /// token, and status, then persisting the changes.
  ///
  /// Parameters:
  /// - [channel]: The [Channel] to update.
  /// - [permanentChannelDid]: The permanent channel DID to set for the channel.
  /// - [otherPartyPermanentChannelDid]: The permanent channel DID to set for
  ///   the other party.
  /// - [notificationToken]: The notification token to set for the channel.
  ///
  /// Returns a [Future] that completes when the update is done.
  ///
  /// Throws a [ChannelServiceException] if validation fails.
  Future<void> markChannelApprovedForConnectionInitiator(
    Channel channel, {
    required String permanentChannelDid,
    required String otherPartyPermanentChannelDid,
    required String notificationToken,
  }) async {
    if (channel.isGroup) {
      throw ChannelServiceException.invalidChannelType(
        expected: [ChannelType.individual, ChannelType.oob],
        actual: channel.type,
      );
    }

    if (!channel.isConnectionInitiator) {
      throw ChannelServiceException.actionNotAllowed(action: 'approveChannel');
    }

    if (!channel.isWaitingForApproval) {
      throw ChannelServiceException.invalidChannelStatus(
        expected: ChannelStatus.waitingForApproval,
        actual: channel.status,
      );
    }

    channel.permanentChannelDid = permanentChannelDid;
    channel.otherPartyPermanentChannelDid = otherPartyPermanentChannelDid;
    channel.notificationToken = notificationToken;
    channel.status = ChannelStatus.approved;
    return _channelRepository.updateChannel(channel);
  }

  /// Sets the status of a channel to inaugurated, updating the notification
  /// token and persisting the changes.
  ///
  /// Parameters:
  /// - [channel]: The [Channel] to update.
  /// - [otherPartyNotificationToken]: The notification token to set for the other party.
  ///
  /// Returns a [Future] that completes when the update is done.
  ///
  /// Throws a [ChannelServiceException] if the channel is not in the
  /// expected status.
  Future<void> markChannelInauguratedForConnectionInitiator(
    Channel channel, {
    required String otherPartyNotificationToken,
  }) {
    if (channel.isGroup) {
      throw ChannelServiceException.invalidChannelType(
        expected: [ChannelType.individual, ChannelType.oob],
        actual: channel.type,
      );
    }

    if (!channel.isConnectionInitiator) {
      throw ChannelServiceException.actionNotAllowed(
        action: 'markChannelInauguratedForConnectionInitiator',
      );
    }

    channel.otherPartyNotificationToken = otherPartyNotificationToken;
    channel.status = ChannelStatus.inaugurated;
    return _channelRepository.updateChannel(channel);
  }

  /// Sets the status of a channel to inaugurated, updating the notification
  /// token, other party's permanent channel DID, outbound message ID, and
  /// other party's contact card, then persisting the changes.
  ///
  /// Parameters:
  /// - [channel]: The [Channel] to update.
  /// - [notificationToken]: The notification token to set for the channel.
  /// - [otherPartyNotificationToken]: The notification token to set for the
  ///   other party.
  /// - [otherPartyPermanentChannelDid]: The permanent channel DID to set for
  ///   the other party.
  /// - [outboundMessageId]: The outbound message ID to set for the channel.
  /// - [otherPartyContactCard]: The contact card to set for the other party.
  ///
  /// Returns a [Future] that completes when the update is done.
  ///
  /// Throws a [ChannelServiceException] if the channel is not in the
  /// expected status.
  Future<void> markChannelInauguratedForNonConnectionInitiator(
    Channel channel, {
    required String notificationToken,
    required String otherPartyNotificationToken,
    required String otherPartyPermanentChannelDid,
    required String outboundMessageId,
    required ContactCard? otherPartyContactCard,
  }) {
    if (!channel.isIndividual) {
      throw ChannelServiceException.invalidChannelType(
        expected: [ChannelType.individual],
        actual: channel.type,
      );
    }

    if (channel.isConnectionInitiator) {
      throw ChannelServiceException.actionNotAllowed(
        action: 'markChannelInauguratedForNonConnectionInitiator',
      );
    }

    channel.notificationToken = notificationToken;
    channel.otherPartyNotificationToken = otherPartyNotificationToken;
    channel.otherPartyPermanentChannelDid = otherPartyPermanentChannelDid;
    channel.outboundMessageId = outboundMessageId;
    channel.otherPartyContactCard = otherPartyContactCard;
    channel.status = ChannelStatus.inaugurated;
    return _channelRepository.updateChannel(channel);
  }

  /// Sets the status of a OOB channel to inaugurated for a non-connection
  /// initiator, updating the other party's permanent channel DID,
  /// outbound message ID, other party's contact card, and persisting the
  /// changes. This method is specifically for OOB channels where notification
  /// tokens are not used.
  ///
  /// Parameters:
  /// - [channel]: The [Channel] to update.
  /// - [otherPartyPermanentChannelDid]: The permanent channel DID to set for
  ///  the other party.
  /// - [outboundMessageId]: The outbound message ID to set for the channel.
  /// - [otherPartyContactCard]: The contact card to set for the other party.
  ///
  /// Returns a [Future] that completes when the update is done.
  ///
  /// Throws a [ChannelServiceException] if the channel is not of type OOB, if
  /// the channel is a connection initiator or if the channel is not in the
  /// expected status.
  Future<void> markOobChannelInauguratedForNonConnectionInitiator(
    Channel channel, {
    required String otherPartyPermanentChannelDid,
    required String outboundMessageId,
    required ContactCard? otherPartyContactCard,
  }) {
    if (!channel.isOob) {
      throw ChannelServiceException.invalidChannelType(
        expected: [ChannelType.oob],
        actual: channel.type,
      );
    }

    if (channel.isConnectionInitiator) {
      throw ChannelServiceException.actionNotAllowed(
        action: 'markChannelInaugurated',
      );
    }

    if (!channel.isWaitingForApproval) {
      throw ChannelServiceException.invalidChannelStatus(
        expected: ChannelStatus.waitingForApproval,
        actual: channel.status,
      );
    }

    channel.otherPartyPermanentChannelDid = otherPartyPermanentChannelDid;
    channel.outboundMessageId = outboundMessageId;
    channel.otherPartyContactCard = otherPartyContactCard;
    channel.status = ChannelStatus.inaugurated;
    return _channelRepository.updateChannel(channel);
  }

  /// Sets the status of a group channel to inaugurated, updating the
  /// notification token, other party's permanent channel DID, sequence number,
  /// and persisting the changes.
  ///
  /// Parameters:
  /// - [channel]: The [Channel] to update.
  /// - [notificationToken]: The notification token to set for the channel.
  /// - [otherPartyPermanentChannelDid]: The permanent channel DID to set for
  ///   the other party.
  /// - [sequenceNumber]: The sequence number to set for the channel.
  ///
  /// Returns a [Future] that completes when the update is done.
  ///
  /// Throws a [ChannelServiceException] if the channel is not in the
  Future<void> markGroupChannelInauguratedFromWaitingForApproval(
    Channel channel, {
    required String notificationToken,
    required String otherPartyPermanentChannelDid,
    required int sequenceNumber,
  }) {
    if (!channel.isGroup) {
      throw ChannelServiceException.invalidChannelType(
        expected: [ChannelType.group],
        actual: channel.type,
      );
    }

    if (!channel.isWaitingForApproval) {
      throw ChannelServiceException.invalidChannelStatus(
        expected: ChannelStatus.waitingForApproval,
        actual: channel.status,
      );
    }

    channel.notificationToken = notificationToken;
    channel.otherPartyPermanentChannelDid = otherPartyPermanentChannelDid;
    channel.seqNo = sequenceNumber;
    channel.status = ChannelStatus.inaugurated;
    return _channelRepository.updateChannel(channel);
  }

  /// Updates the sequence number and message sync marker of a channel and
  /// persisting the changes.
  ///
  /// Parameters:
  /// - [channel]: The [Channel] to update.
  /// - [sequenceNumber]: The new [Channel.seqNo] to set.
  /// - [messageSyncMarker]: The new [Channel.messageSyncMarker] to set.
  ///
  /// Returns a [Future] that completes when the update is done.
  Future<void> updateChannelSequence(
    Channel channel, {
    required int sequenceNumber,
    required DateTime? messageSyncMarker,
  }) async {
    channel.seqNo = sequenceNumber;
    channel.messageSyncMarker = messageSyncMarker;
    return _channelRepository.updateChannel(channel);
  }
}
