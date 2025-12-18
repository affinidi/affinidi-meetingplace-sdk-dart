import 'package:json_annotation/json_annotation.dart';
import '../contact_card/contact_card.dart';

import 'connection_offer.dart';

part 'group_connection_offer.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class GroupConnectionOffer extends ConnectionOffer {
  GroupConnectionOffer({
    required this.groupId,
    this.groupDid,
    this.groupOwnerDid,
    this.memberDid,
    this.metadata,
    required super.offerName,
    required super.offerLink,
    required super.mnemonic,
    required super.publishOfferDid,
    required super.mediatorDid,
    required super.offerDescription,
    required super.oobInvitationMessage,
    required super.type,
    required super.status,
    required super.contactCard,
    required super.ownedByMe,
    required super.createdAt,
    super.expiresAt,
    super.maximumUsage,
    super.outboundMessageId,
    super.acceptOfferDid,
    super.permanentChannelDid,
    super.otherPartyPermanentChannelDid,
    super.notificationToken,
    super.otherPartyNotificationToken,
    super.externalRef,
  });

  factory GroupConnectionOffer.fromJson(Map<String, dynamic> json) {
    return _$GroupConnectionOfferFromJson(json);
  }
  final String groupId;
  final String? groupDid;
  final String? groupOwnerDid;
  final String? memberDid;
  final String? metadata;

  @override
  GroupConnectionOffer copyWith({
    String? groupId,
    String? groupDid,
    String? memberDid,
    String? groupOwnerDid,
    String? metadata,
    ContactCard? card,
    String? outboundMessageId,
    String? otherPartyPermanentChannelDid,
    String? acceptOfferDid,
    String? permanentChannelDid,
    ConnectionOfferStatus? status,
    String? notificationToken,
    String? otherPartyNotificationToken,
    int? maximumUsage,
    DateTime? createdAt,
    String? externalRef,
  }) {
    return GroupConnectionOffer(
      groupId: groupId ?? this.groupId,
      groupDid: groupDid ?? this.groupDid,
      memberDid: memberDid ?? this.memberDid,
      groupOwnerDid: groupOwnerDid ?? this.groupOwnerDid,
      metadata: metadata ?? this.metadata,
      offerLink: offerLink,
      offerName: offerName,
      offerDescription: offerDescription,
      mnemonic: mnemonic,
      expiresAt: expiresAt,
      publishOfferDid: publishOfferDid,
      mediatorDid: mediatorDid,
      oobInvitationMessage: oobInvitationMessage,
      maximumUsage: maximumUsage ?? this.maximumUsage,
      type: type,
      contactCard: card ?? contactCard,
      outboundMessageId: outboundMessageId ?? this.outboundMessageId,
      permanentChannelDid: permanentChannelDid ?? this.permanentChannelDid,
      otherPartyPermanentChannelDid:
          otherPartyPermanentChannelDid ?? this.otherPartyPermanentChannelDid,
      acceptOfferDid: acceptOfferDid ?? this.acceptOfferDid,
      status: status ?? this.status,
      notificationToken: notificationToken ?? this.notificationToken,
      otherPartyNotificationToken:
          otherPartyNotificationToken ?? this.otherPartyNotificationToken,
      externalRef: externalRef,
      createdAt: createdAt ?? this.createdAt,
      ownedByMe: ownedByMe,
    );
  }

  GroupConnectionOffer acceptGroupOffer({
    required String groupId,
    required String memberDid,
    required String acceptOfferDid,
    required String permanentChannelDid,
    required DateTime createdAt,
    ContactCard? card,
    String? externalRef,
  }) {
    return copyWith(
      groupId: groupId,
      memberDid: memberDid,
      acceptOfferDid: acceptOfferDid,
      permanentChannelDid: permanentChannelDid,
      status: ConnectionOfferStatus.accepted,
      card: card,
      externalRef: externalRef,
      createdAt: createdAt,
    );
  }

  GroupConnectionOffer groupFinalise({
    required String groupId,
    required String groupDid,
    required int seqNo,
    required String notificationToken,
  }) {
    return copyWith(
      groupId: groupId,
      groupDid: groupDid,
      notificationToken: notificationToken,
      status: ConnectionOfferStatus.finalised,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return _$GroupConnectionOfferToJson(this);
  }

  @override
  GroupConnectionOffer markAsDeleted() {
    return copyWith(status: ConnectionOfferStatus.deleted);
  }
}
