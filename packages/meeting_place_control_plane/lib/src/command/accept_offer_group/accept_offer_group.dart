import '../../core/command/command.dart';
import '../../core/device/device.dart';
import '../../core/protocol/v_card/v_card.dart';
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
    required this.vCard,
    required this.acceptOfferDid,
  });
  final String mnemonic;
  final Device device;
  final String offerLink;
  final VCard vCard;
  final String acceptOfferDid;
}
