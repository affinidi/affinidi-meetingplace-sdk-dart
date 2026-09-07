import '../../core/command/command.dart';
import '../../core/device/device.dart';
import '../../core/protocol/contact_card/contact_card.dart';
import 'finalise_acceptance_output.dart';

/// Model that represents the request sent for the [FinaliseAcceptanceRequest]
/// operation.
class FinaliseAcceptanceRequest
    extends DiscoveryCommand<FinaliseAcceptanceOutput> {
  /// Creates a new instance of [FinaliseAcceptanceRequest].
  FinaliseAcceptanceRequest({
    required this.mnemonic,
    required this.offerLink,
    required this.offerPublishedDid,
    required this.otherPartyAcceptOfferDid,
    required this.otherPartyPermanentChannelDid,
    required this.device,
    this.contactCard,
  });

  /// The mnemonic identifier of the offer being finalised.
  final String mnemonic;

  /// The link of the offer being finalised.
  final String offerLink;

  /// The DID under which the offer was originally published.
  final String offerPublishedDid;

  /// The DID the other party used to accept the offer.
  final String otherPartyAcceptOfferDid;

  /// The DID of the other party's permanent connection channel.
  final String otherPartyPermanentChannelDid;

  /// The device the acceptance is being finalised on.
  final Device device;

  /// The contact card sharing the identity of the finalising party, if any.
  final ContactCard? contactCard;
}
