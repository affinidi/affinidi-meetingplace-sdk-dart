import 'package:didcomm/didcomm.dart' show Attachment;

import '../../entity/connection_offer.dart';
import '../../protocol/contact_card/contact_card.dart';

/// Builds what a member sends a group's owner to be let in, given the DID
/// the member will be known by in the group, so a proof can name it.
typedef GroupJoinAttachmentsBuilder =
    Future<List<Attachment>> Function(String memberDid);

/// Parameters for `MeetingPlaceCoreSDK.acceptOffer`.
class AcceptOfferRequest<T extends ConnectionOffer> {
  /// Creates an [AcceptOfferRequest].
  const AcceptOfferRequest({
    required this.connectionOffer,
    required this.contactCard,
    required this.senderInfo,
    this.externalRef,
    this.buildGroupJoinAttachments,
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

  /// For a group offer, builds attachments sent to the group's owner with
  /// the join request, after the contact card, such as credentials that
  /// prove a right to join. Ignored for other offers.
  final GroupJoinAttachmentsBuilder? buildGroupJoinAttachments;
}
