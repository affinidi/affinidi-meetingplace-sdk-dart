import '../../core/command/command.dart';
import '../../core/device/device.dart';
import '../../core/protocol/contact_card/contact_card.dart';
import 'accept_offer_group_output.dart';

/// Model that represents the request sent for the [AcceptOfferGroupCommand]
/// operation.
class AcceptOfferGroupCommand
    extends DiscoveryCommand<AcceptOfferGroupCommandOutput> {
  /// Creates a new instance of [AcceptOfferGroupCommand].
  AcceptOfferGroupCommand({
    required this.mnemonic,
    required this.device,
    required this.offerLink,
    required this.contactCard,
    required this.acceptOfferDid,
  });
  final String mnemonic;
  final Device device;
  final String offerLink;
  final ContactCard contactCard;
  final String acceptOfferDid;
}
