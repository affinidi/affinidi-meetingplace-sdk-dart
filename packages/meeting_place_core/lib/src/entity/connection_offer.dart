import 'package:json_annotation/json_annotation.dart';
import '../entity/contact_card.dart';

part 'connection_offer.g.dart';

enum ConnectionOfferType {
  meetingPlaceInvitation,
  meetingPlaceOutreachInvitation,
}

enum ConnectionOfferStatus {
  published,
  finalised,
  accepted,
  channelInaugurated,
  deleted,
}

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ConnectionOffer {
  ConnectionOffer({
    required this.offerName,
    required this.offerLink,
    required this.mnemonic,
    required this.publishOfferDid,
    required this.mediatorDid,
    required this.oobInvitationMessage,
    required this.type,
    required this.status,
    required this.contactCard,
    required this.ownedByMe,
    required this.createdAt,
    this.expiresAt,
    this.maximumUsage,
    this.offerDescription,
    this.outboundMessageId,
    this.acceptOfferDid,
    this.permanentChannelDid,
    this.otherPartyPermanentChannelDid,
    this.notificationToken,
    this.otherPartyNotificationToken,
    this.externalRef,
  });

  factory ConnectionOffer.fromJson(Map<String, dynamic> json) {
    return _$ConnectionOfferFromJson(json);
  }
  final String offerName;
  final String offerLink;
  final String? offerDescription;
  final String mnemonic;
  final DateTime createdAt;
  final String publishOfferDid;
  final String mediatorDid;
  final String oobInvitationMessage;
  final ContactCard contactCard;
  final ConnectionOfferType type;
  final ConnectionOfferStatus status;
  final bool ownedByMe;

  final DateTime? expiresAt;
  final int? maximumUsage;
  final String? outboundMessageId;
  final String? acceptOfferDid;
  final String? permanentChannelDid;
  final String? otherPartyPermanentChannelDid;

  final String? notificationToken;

  /// Other's party notification token that is used to notify the other party.
  ///
  /// If connection offer lives on device of offer owner, notification token
  /// is the token shared by the accepting party.
  ///
  /// If connection offer lives on device of accepting party, notification token
  /// is the token shared by the offer owner.
  final String? otherPartyNotificationToken;

  final String? externalRef;

  Map<String, dynamic> toJson() {
    return _$ConnectionOfferToJson(this);
  }

  bool get isFinalised => status == ConnectionOfferStatus.finalised;
  bool get isPublished => status == ConnectionOfferStatus.published;
  bool get isAccepted => status == ConnectionOfferStatus.accepted;
  bool get isDeleted => status == ConnectionOfferStatus.deleted;

  ConnectionOffer copyWith({
    ContactCard? card,
    String? outboundMessageId,
    String? otherPartyPermanentChannelDid,
    String? acceptOfferDid,
    String? permanentChannelDid,
    ConnectionOfferStatus? status,
    String? notificationToken,
    String? otherPartyNotificationToken,
    int? maximumUsage,
    String? externalRef,
    DateTime? createdAt,
  }) {
    return ConnectionOffer(
      offerLink: offerLink,
      offerName: offerName,
      offerDescription: offerDescription,
      mnemonic: mnemonic,
      expiresAt: expiresAt,
      publishOfferDid: publishOfferDid,
      mediatorDid: mediatorDid,
      oobInvitationMessage: oobInvitationMessage,
      type: type,
      contactCard: card ?? this.contactCard,
      outboundMessageId: outboundMessageId ?? this.outboundMessageId,
      permanentChannelDid: permanentChannelDid ?? this.permanentChannelDid,
      otherPartyPermanentChannelDid:
          otherPartyPermanentChannelDid ?? this.otherPartyPermanentChannelDid,
      acceptOfferDid: acceptOfferDid ?? this.acceptOfferDid,
      maximumUsage: maximumUsage ?? this.maximumUsage,
      status: status ?? this.status,
      notificationToken: notificationToken ?? this.notificationToken,
      otherPartyNotificationToken:
          otherPartyNotificationToken ?? this.otherPartyNotificationToken,
      externalRef: externalRef ?? this.externalRef,
      createdAt: createdAt ?? this.createdAt,
      ownedByMe: ownedByMe,
    );
  }

  ConnectionOffer accept({
    required String acceptOfferDid,
    required String permanentChannelDid,
    required ContactCard card,
    required DateTime createdAt,
    String? externalRef,
  }) {
    return copyWith(
      acceptOfferDid: acceptOfferDid,
      permanentChannelDid: permanentChannelDid,
      status: ConnectionOfferStatus.accepted,
      card: card,
      createdAt: createdAt,
      externalRef: externalRef,
    );
  }

  ConnectionOffer accepted({
    required String outboundMessageId,
    required String acceptOfferDid,
    required String otherPartyPermanentChannelDid,
  }) {
    return copyWith(
      outboundMessageId: outboundMessageId,
      acceptOfferDid: acceptOfferDid,
      otherPartyPermanentChannelDid: otherPartyPermanentChannelDid,
    );
  }

  ConnectionOffer finalise({
    required String permanentChannelDid,
    required String otherPartyPermanentChannelDid,
  }) {
    return copyWith(
      permanentChannelDid: permanentChannelDid,
      otherPartyPermanentChannelDid: otherPartyPermanentChannelDid,
    );
  }

  ConnectionOffer finalised({
    required String notificationToken,
    required String outboundMessageId,
    required String otherPartyPermanentChannelDid,
    required String otherPartyNotificationToken,
    int seqNo = 0,
  }) {
    return copyWith(
      notificationToken: notificationToken,
      outboundMessageId: outboundMessageId,
      otherPartyPermanentChannelDid: otherPartyPermanentChannelDid,
      otherPartyNotificationToken: otherPartyNotificationToken,
      status: ConnectionOfferStatus.finalised,
    );
  }

  ConnectionOffer channelInauguration({
    required String notificationToken,
    required String otherPartyPermanentChannelDid,
  }) {
    return copyWith(
      notificationToken: notificationToken,
      otherPartyPermanentChannelDid: otherPartyPermanentChannelDid,
    );
  }

  ConnectionOffer inaugurateChannelDone({required String notificationToken}) {
    return copyWith(notificationToken: notificationToken);
  }

  ConnectionOffer markAsDeleted() {
    return copyWith(status: ConnectionOfferStatus.deleted);
  }
}
