import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../meeting_place_core.dart';

part 'channel.g.dart';

enum ChannelStatus { waitingForApproval, inaugurated, approved }

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
    this.otherPartyContactCard,
    this.outboundMessageId,
    this.acceptOfferDid,
    this.permanentChannelDid,
    this.otherPartyPermanentChannelDid,
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
      contactCard: contactCard,
      otherPartyContactCard: connectionOffer.contactCard,
      externalRef: externalRef,
    );
  }

  factory Channel.groupFromAcceptedConnectionOffer(
    GroupConnectionOffer connectionOffer, {
    required String permanentChannelDid,
    required String acceptOfferDid,
    required ContactCard card,
    required String? externalRef,
  }) {
    return Channel(
      offerLink: connectionOffer.offerLink,
      publishOfferDid: connectionOffer.publishOfferDid,
      permanentChannelDid: permanentChannelDid,
      acceptOfferDid: acceptOfferDid,
      mediatorDid: connectionOffer.mediatorDid,
      status: ChannelStatus.waitingForApproval,
      type: ChannelType.group,
      contactCard: card,
      otherPartyContactCard: connectionOffer.contactCard,
      externalRef: externalRef,
    );
  }

  @JsonKey()
  final String id;
  final String publishOfferDid;
  final String mediatorDid;
  final String offerLink;
  final ChannelType type;
  ContactCard? contactCard;
  ContactCard? otherPartyContactCard;
  ChannelStatus status;

  String? outboundMessageId;
  String? acceptOfferDid;
  String? permanentChannelDid;
  String? otherPartyPermanentChannelDid;
  String? notificationToken;

  /// Other's party notification token that is used to notify the other party.
  ///
  /// If connection offer lives on device of offer owner, notification token
  /// is the token shared by the accepting party.
  ///
  /// If connection offer lives on device of accepting party, notification token
  /// is the token shared by the offer owner.
  String? otherPartyNotificationToken;

  String? externalRef;

  int seqNo = 0;

  /// Message sync marker can be used to fetch messages from mediator instance
  /// to only fetch messages that have not been fetched before.
  DateTime? messageSyncMarker;

  @JsonKey(includeToJson: false, includeFromJson: false)
  List<Attachment>? receivedAttachments;

  bool get isGroup => type == ChannelType.group;

  bool get isInaugurated => status == ChannelStatus.inaugurated;

  bool get isApproved => status == ChannelStatus.approved;

  Map<String, dynamic> toJson() {
    return _$ChannelToJson(this);
  }

  void increaseSeqNo() {
    seqNo++;
  }
}
