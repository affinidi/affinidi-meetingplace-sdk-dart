import '../../core/command/command.dart';
import '../../core/device/device.dart';
import '../../protocol/v_card/v_card.dart';
import 'accept_offer_output.dart';

typedef SuccessCallback = void Function();
typedef ErrorCallback = void Function();
typedef TimeoutCallback = void Function();
typedef FinishedCallback = void Function();

/// Model that represents the request sent for the [AcceptOfferCommand]
/// operation.
class AcceptOfferCommand extends DiscoveryCommand<AcceptOfferCommandOutput> {
  /// Creates a new instance of [AcceptOfferCommand].
  AcceptOfferCommand({
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
