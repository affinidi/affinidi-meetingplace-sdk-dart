import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../meeting_place_core.dart';

part 'channel.g.dart';

enum ChannelStatus {
  /// Indicates that the accepting party has accepted the offer, and is waiting
  /// for the offer owner to approve the acceptance request.
  waitingForApproval,

  /// Indicates that the channel has been approved by the offer owner, but has
  /// not been inaugurated yet. This status can only be set by the offer owner.
  approved,

  /// Indicates that the channel has been inaugurated, and both parties can
  /// start to exchange messages.
  inaugurated,
}

enum ChannelType { individual, group, oob }

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class Channel {
  Channel({
    String? id,
    required this.offerLink,
    required this.publishOfferDid,
    required this.mediatorDid,
    required this.status,
    required this.contactCard,
    required this.type,
    required this.isConnectionInitiator,
    this.otherPartyContactCard,
    this.outboundMessageId,
    this.acceptOfferDid,
    this.permanentChannelDid,
    this.otherPartyPermanentChannelDid,
    this.matrixUserId,
    this.otherPartyMatrixUserId,
    this.notificationToken,
    this.otherPartyNotificationToken,
    this.messageSyncMarker,
    this.seqNo = 0,
    this.externalRef,
  }) : id = id ?? const Uuid().v4();

  factory Channel.fromJson(Map<String, dynamic> json) {
    return _$ChannelFromJson(json);
  }

  factory Channel.individualFromAcceptedConnectionOffer(
    ConnectionOffer connectionOffer, {
    required String permanentChannelDid,
    required String acceptOfferDid,
    required ContactCard contactCard,
    required String? externalRef,
  }) {
    return Channel(
      offerLink: connectionOffer.offerLink,
      publishOfferDid: connectionOffer.publishOfferDid,
      permanentChannelDid: permanentChannelDid,
      acceptOfferDid: acceptOfferDid,
      mediatorDid: connectionOffer.mediatorDid,
      status: ChannelStatus.waitingForApproval,
      type: ChannelType.individual,
      isConnectionInitiator: false,
      contactCard: contactCard,
      otherPartyContactCard: connectionOffer.contactCard,
      externalRef: externalRef,
    );
  }

  factory Channel.groupFromAcceptedConnectionOffer(
    GroupConnectionOffer connectionOffer, {
    required String permanentChannelDid,
    required String acceptOfferDid,
    required String matrixUserId,
    required ContactCard card,
    required String? externalRef,
  }) {
    return Channel(
      offerLink: connectionOffer.offerLink,
      publishOfferDid: connectionOffer.publishOfferDid,
      permanentChannelDid: permanentChannelDid,
      acceptOfferDid: acceptOfferDid,
      matrixUserId: matrixUserId,
      mediatorDid: connectionOffer.mediatorDid,
      status: ChannelStatus.waitingForApproval,
      type: ChannelType.group,
      isConnectionInitiator: false,
      contactCard: card,
      otherPartyContactCard: connectionOffer.contactCard,
      externalRef: externalRef,
    );
  }

  /// Unique identifier for the channel, generated when creating a channel.
  @JsonKey()
  final String id;

  /// DID used to publish the connection offer.
  final String publishOfferDid;

  /// DID of the mediator that the channel uses to exchange messages.
  final String mediatorDid;

  /// Offer identifier that can be used to correlate the channel with the
  /// connection offer.
  final String offerLink;

  /// Type of the channel that indicates whether the channel is created from an
  /// individual connection offer, a group connection offer, or an out-of-band
  /// invitation.
  final ChannelType type;

  /// Indicates whether the channel was initiated by the local party or the
  /// other party.
  final bool isConnectionInitiator;

  /// Contact card of the channel owner.
  ContactCard? contactCard;

  /// Contact card of the other party.
  ContactCard? otherPartyContactCard;

  /// Status of the channel that indicates the current stage of the channel in
  /// the channel lifecycle.
  ChannelStatus status;

  /// Outbound message id that initiated the channel.
  String? outboundMessageId;

  /// DID that was used to accept the connection offer.
  String? acceptOfferDid;

  /// Permanent DID that is used for message exchange.
  String? permanentChannelDid;

  /// Permanent DID of the other party that is used for message exchange.
  String? otherPartyPermanentChannelDid;

  /// Matrix user id of the other party that is used for message exchange.
  String? matrixUserId;

  /// Matrix user id of the other party that is used for message exchange.
  String? otherPartyMatrixUserId;

  /// Notification token that is used to notify the party that owns the channel.
  ///
  /// If connection offer lives on device of offer owner, notification token
  /// is the token shared by the offer owner.
  ///
  /// If connection offer lives on device of accepting party, notification token
  /// is the token shared by the accepting party.
  String? notificationToken;

  /// Other's party notification token that is used to notify the other party.
  ///
  /// If connection offer lives on device of offer owner, notification token
  /// is the token shared by the accepting party.
  ///
  /// If connection offer lives on device of accepting party, notification token
  /// is the token shared by the offer owner.
  String? otherPartyNotificationToken;

  /// External reference that can be used to correlate the channel with external
  /// systems. This field is not used by the SDK, and can be set by the SDK
  /// consumer to store any relevant information that can be used to correlate
  /// the channel with external systems or data.
  String? externalRef;

  /// Sequence number to keep track of latest message in the channel.
  int seqNo = 0;

  /// Message sync marker can be used to fetch messages from mediator instance
  /// to only fetch messages that have not been fetched before.
  DateTime? messageSyncMarker;

  /// Check if the channel is of type individual.
  bool get isIndividual => type == ChannelType.individual;

  /// Check if the channel is of type out-of-band.
  bool get isOob => type == ChannelType.oob;

  /// Check if the channel is of type group.
  bool get isGroup => type == ChannelType.group;

  /// Check if the channel is in the inaugurated status.
  bool get isInaugurated => status == ChannelStatus.inaugurated;

  /// Check if the channel is in the approved status.
  bool get isApproved => status == ChannelStatus.approved;

  /// Check if the channel is waiting for approval.
  bool get isWaitingForApproval => status == ChannelStatus.waitingForApproval;

  Map<String, dynamic> toJson() {
    return _$ChannelToJson(this);
  }

  void increaseSeqNo() {
    seqNo++;
  }
}
