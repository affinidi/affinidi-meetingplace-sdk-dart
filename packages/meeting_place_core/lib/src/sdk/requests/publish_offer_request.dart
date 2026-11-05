import '../../entity/channel.dart' show ChannelTransport;
import '../../protocol/contact_card/contact_card.dart';
import '../connection_offer_type.dart';

/// Parameters for `MeetingPlaceCoreSDK.publishOffer`.
class PublishOfferRequest {
  /// Creates a [PublishOfferRequest].
  const PublishOfferRequest({
    required this.offerName,
    required this.type,
    required this.contactCard,
    required this.offerDescription,
    this.customMnemonic,
    this.validUntil,
    this.maximumUsage,
    this.mediatorDid,
    this.metadata,
    this.externalRef,
    this.transport = ChannelTransport.didcomm,
    this.score,
    this.groupDid,
  });

  /// The name of your offer as it will be displayed when others search for
  /// offers.
  final String offerName;

  /// Type of the offer. Either invitation, outreachInvitation or
  /// groupInvitation.
  final SDKConnectionOfferType type;

  /// A ContactCard that contains information about who is offering the
  /// offer. This helps others know whom they are connecting with and
  /// provides necessary contact details.
  final ContactCard contactCard;

  /// Description of the offer to indicate the purpose of the offer.
  final String offerDescription;

  /// A custom phrase or keyword to help your offer be found more easily by
  /// specific searches on MeetingPlace. If not provided, a generic mnemonic
  /// will be used.
  final String? customMnemonic;

  /// The date and time when the offer expires. Once this date is reached,
  /// the offer will no longer be available.
  final DateTime? validUntil;

  /// The maximum number of times the offer can be queried or accepted. Once
  /// this limit is reached, no further queries or acceptances will be
  /// allowed.
  final int? maximumUsage;

  /// The specific Mediator DID to be used for this offer. If not provided,
  /// the default SDK Mediator DID will be used.
  final String? mediatorDid;

  /// The additional data related to the offer to be published.
  final String? metadata;

  /// Application-specific data that is passed through to internal entities,
  /// such as connection offers and channels, and can be referenced later
  /// for tracking or identification purposes. [externalRef] is accessible
  /// on the current device only.
  final String? externalRef;

  /// Transport used for message exchange on the resulting channel.
  final ChannelTransport transport;

  /// Initial VRC score to associate with the published offer.
  final int? score;

  /// For a group invitation, the DID the group is known by when it is held
  /// elsewhere, such as a VTC community group's. The group's keys are never
  /// needed: its DID only names the group and its Matrix room, and the
  /// homeserver gives one room per DID, so a second group with the same DID
  /// cannot be published.
  ///
  /// When null, a `did:key` is generated on this device. Ignored for other
  /// offer types.
  final String? groupDid;
}
