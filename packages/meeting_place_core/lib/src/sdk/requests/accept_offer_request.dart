import '../../entity/connection_offer.dart';
import '../../protocol/contact_card/contact_card.dart';

/// Parameters for `MeetingPlaceCoreSDK.acceptOffer`.
class AcceptOfferRequest<T extends ConnectionOffer> {
  const AcceptOfferRequest({
    required this.connectionOffer,
    required this.contactCard,
    required this.senderInfo,
    this.externalRef,
  });

  /// The connection offer being accepted.
  final T connectionOffer;

  /// A [ContactCard] that contains information about who is accepting the
  /// offer. This helps the offeree to know who accepted it.
  final ContactCard contactCard;

  /// Value to be shown in notification message to the other party.
  final String senderInfo;

  /// Application-specific data that is passed through to internal entities,
  /// such as connection offers and channels, and can be referenced later
  /// for tracking or identification purposes. [externalRef] is accessible
  /// on the current device only.
  final String? externalRef;
}
