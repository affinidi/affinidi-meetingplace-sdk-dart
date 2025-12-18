import '../../core/command/command.dart';
import '../../core/device/device.dart';
import '../../core/protocol/contact_card/contact_card.dart';
import 'finalise_acceptance_output.dart';

/// Model that represents the request sent for the [FinaliseAcceptanceCommand]
/// operation.
class FinaliseAcceptanceCommand
    extends DiscoveryCommand<FinaliseAcceptanceOutput> {
  /// Creates a new instance of [FinaliseAcceptanceCommand].
  FinaliseAcceptanceCommand({
    required this.mnemonic,
    required this.offerLink,
    required this.offerPublishedDid,
    required this.otherPartyAcceptOfferDid,
    required this.otherPartyPermanentChannelDid,
    required this.device,
    this.contactCard,
  });
  final String mnemonic;
  final String offerLink;
  final String offerPublishedDid;
  final String otherPartyAcceptOfferDid;
  final String otherPartyPermanentChannelDid;
  final Device device;
  final ContactCard? contactCard;
}
