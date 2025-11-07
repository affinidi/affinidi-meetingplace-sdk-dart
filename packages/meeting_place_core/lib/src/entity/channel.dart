import 'package:json_annotation/json_annotation.dart';
import '../protocol/v_card/v_card.dart';
import 'package:uuid/uuid.dart';

import 'connection_offer.dart';
import 'entity.dart';

part 'channel.g.dart';

enum ChannelStatus { waitingForApproval, inaugaurated, approved }

enum ChannelType { individual, group, oob }

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class Channel {
  Channel({
    String? id,
    required this.offerLink,
    required this.publishOfferDid,
    required this.mediatorDid,
    required this.status,
    required this.vCard,
    required this.type,
    this.otherPartyVCard,
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
    required VCard vCard,
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
      vCard: vCard,
      otherPartyVCard: connectionOffer.vCard,
      externalRef: externalRef,
    );
  }

  factory Channel.groupFromAcceptedConnectionOffer(
    GroupConnectionOffer connectionOffer, {
    required String permanentChannelDid,
    required String acceptOfferDid,
    required VCard vCard,
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
      vCard: vCard,
      otherPartyVCard: connectionOffer.vCard,
      externalRef: externalRef,
    );
  }

  @JsonKey()
  final String id;
  final String publishOfferDid;
  final String mediatorDid;
  final String offerLink;
  final ChannelType type;
  VCard? vCard;
  VCard? otherPartyVCard;
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

  bool get isGroup => type == ChannelType.group;

  bool get isInaugurated => status == ChannelStatus.inaugaurated;

  Map<String, dynamic> toJson() {
    return _$ChannelToJson(this);
  }

  void increaseSeqNo() {
    seqNo++;
  }
}
