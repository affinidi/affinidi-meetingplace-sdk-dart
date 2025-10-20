import '../../core/offer_type.dart';
import '../../protocol/message/oob_invitation_message.dart';
import '../../protocol/v_card/v_card.dart';

abstract class QueryOfferCommandOutput {}

/// Model that represents the output data returned from a successful execution
/// of [SuccessQueryOfferCommandOutput] operation.
class SuccessQueryOfferCommandOutput extends QueryOfferCommandOutput {
  /// Creates a new instance of [SuccessQueryOfferCommandOutput].
  SuccessQueryOfferCommandOutput({
    required this.offerName,
    required this.offerLink,
    required this.offerDescription,
    required this.type,
    required this.mnemonic,
    required this.vCard,
    required this.expiresAt,
    required this.maximumUsage,
    required this.mediatorDid,
    required this.status,
    required this.didcommMessage,
    this.groupId,
    this.groupDid,
  });
  final String offerName;
  final String offerLink;
  final String offerDescription;
  final OfferType type;
  final String mnemonic;
  final VCard vCard;
  final DateTime? expiresAt;
  final int? maximumUsage;
  final String mediatorDid;
  final String status;
  final OobInvitationMessage didcommMessage;
  final String? groupId;
  final String? groupDid;

  bool get isInvitation => type == OfferType.invitation;
  bool get isGroupInvitation => type == OfferType.groupInvitation;
  bool get isOutreachInvitation => type == OfferType.outreachInvitation;
}

class NullQueryOfferCommandOutput extends QueryOfferCommandOutput {}
