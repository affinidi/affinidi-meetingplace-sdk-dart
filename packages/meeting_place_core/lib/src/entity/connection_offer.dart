import 'package:json_annotation/json_annotation.dart';

import '../protocol/contact_card/contact_card.dart';
import 'channel.dart';

part 'connection_offer.g.dart';

/// The kind of invitation a [ConnectionOffer] was published as.
enum ConnectionOfferType {
  /// An invitation published for a party to discover and accept.
  meetingPlaceInvitation,

  /// An invitation sent as outreach to a specific prospective contact.
  meetingPlaceOutreachInvitation,
}

/// The stage of a [ConnectionOffer] in its lifecycle.
enum ConnectionOfferStatus {
  /// The offer has been published and is available to be accepted.
  published,

  /// The offer's channel details have been finalised between both parties.
  finalised,

  /// The offer has been accepted by another party.
  accepted,

  /// The channel resulting from the offer has been inaugurated.
  channelInaugurated,

  /// The offer has been deleted.
  deleted,
}

/// An offer to connect, published by one party and accepted by another to
/// establish a [Channel].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ConnectionOffer {
  /// Creates a [ConnectionOffer].
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
    required this.transport,
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
    this.score,
  });

  /// Creates a [ConnectionOffer] from its JSON representation.
  factory ConnectionOffer.fromJson(Map<String, dynamic> json) {
    return _$ConnectionOfferFromJson(json);
  }

  /// The display name of the offer.
  final String offerName;

  /// The link used to share and accept the offer.
  final String offerLink;

  /// An optional human-readable description of the offer.
  final String? offerDescription;

  /// A mnemonic identifying the offer.
  final String mnemonic;

  /// When the offer was created.
  final DateTime createdAt;

  /// DID used to publish the offer.
  final String publishOfferDid;

  /// DID of the mediator used to exchange messages for this offer.
  final String mediatorDid;

  /// The out-of-band invitation message backing this offer.
  final String oobInvitationMessage;

  /// Contact card of the offer owner.
  final ContactCard contactCard;

  /// The kind of invitation this offer was published as.
  final ConnectionOfferType type;

  /// The current stage of the offer in its lifecycle.
  final ConnectionOfferStatus status;

  /// Whether this offer was published by the local party.
  final bool ownedByMe;

  /// When the offer expires, if it has an expiry.
  final DateTime? expiresAt;

  /// The maximum number of times the offer can be accepted, if limited.
  final int? maximumUsage;

  /// Outbound message id that initiated the finalisation of this offer.
  final String? outboundMessageId;

  /// DID that was used to accept the offer.
  final String? acceptOfferDid;

  /// Permanent DID that is used for message exchange.
  final String? permanentChannelDid;

  /// Permanent DID of the other party that is used for message exchange.
  final String? otherPartyPermanentChannelDid;

  /// Notification token used to notify the party that owns the offer.
  final String? notificationToken;

  /// Other's party notification token that is used to notify the other party.
  ///
  /// If connection offer lives on device of offer owner, notification token
  /// is the token shared by the accepting party.
  ///
  /// If connection offer lives on device of accepting party, notification token
  /// is the token shared by the offer owner.
  final String? otherPartyNotificationToken;

  /// External reference that can be used to correlate the offer with
  /// external systems. This field is not used by the SDK, and can be set by
  /// the SDK consumer to store any relevant information.
  final String? externalRef;

  /// Transport selected by the publisher for this offer. Determines which
  /// transport ([ChannelTransport]) for messaging the resulting [Channel]
  /// will use.
  ///
  /// Only meaningful for individual offers. Group offers always use
  /// [ChannelTransport.matrix] regardless of this value.
  final ChannelTransport transport;

  /// VRC score of the offer owner.
  final int? score;

  /// Converts this offer to its JSON representation.
  Map<String, dynamic> toJson() {
    return _$ConnectionOfferToJson(this);
  }

  /// Whether this offer is in the finalised status.
  bool get isFinalised => status == ConnectionOfferStatus.finalised;

  /// Whether this offer is in the published status.
  bool get isPublished => status == ConnectionOfferStatus.published;

  /// Whether this offer is in the accepted status.
  bool get isAccepted => status == ConnectionOfferStatus.accepted;

  /// Whether this offer is in the deleted status.
  bool get isDeleted => status == ConnectionOfferStatus.deleted;

  /// Returns a copy of this offer with the given fields replaced.
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
    ChannelTransport? transport,
    int? score,
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
      contactCard: card ?? contactCard,
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
      transport: transport ?? this.transport,
      score: score ?? this.score,
    );
  }

  /// Returns a copy of this offer marked as accepted by another party.
  ConnectionOffer accept({
    required String acceptOfferDid,
    required String permanentChannelDid,
    required ContactCard card,
    required DateTime createdAt,
    String? externalRef,
    int? score,
  }) {
    return copyWith(
      acceptOfferDid: acceptOfferDid,
      permanentChannelDid: permanentChannelDid,
      status: ConnectionOfferStatus.accepted,
      card: card,
      createdAt: createdAt,
      externalRef: externalRef,
      score: score ?? this.score,
    );
  }

  /// Populates the permanent channel DIDs once both parties have exchanged
  /// them. Does not change [status] — see [finalised] for the transition
  /// that also marks the offer as finalised.
  ConnectionOffer finalise({
    required String permanentChannelDid,
    required String otherPartyPermanentChannelDid,
  }) {
    return copyWith(
      permanentChannelDid: permanentChannelDid,
      otherPartyPermanentChannelDid: otherPartyPermanentChannelDid,
    );
  }

  /// Records the notification tokens exchanged during finalisation and
  /// transitions [status] to [ConnectionOfferStatus.finalised]. Compare with
  /// [finalise], which only populates the permanent channel DIDs without
  /// changing [status].
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

  /// Returns a copy of this offer marked as deleted.
  ConnectionOffer markAsDeleted() {
    return copyWith(status: ConnectionOfferStatus.deleted);
  }
}
