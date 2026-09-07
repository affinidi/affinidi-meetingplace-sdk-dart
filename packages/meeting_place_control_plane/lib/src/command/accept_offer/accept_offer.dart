import '../../core/command/command.dart';
import '../../core/device/device.dart';
import '../../core/protocol/contact_card/contact_card.dart';
import 'accept_offer_output.dart';

typedef SuccessCallback = void Function();
typedef ErrorCallback = void Function();
typedef TimeoutCallback = void Function();
typedef FinishedCallback = void Function();

/// Model that represents the request sent for the [AcceptOfferRequest]
/// operation.
class AcceptOfferRequest extends DiscoveryCommand<AcceptOfferCommandOutput> {
  /// Creates a new instance of [AcceptOfferRequest].
  AcceptOfferRequest({
    required this.mnemonic,
    required this.device,
    required this.offerLink,
    required this.contactCard,
    required this.acceptOfferDid,
  });

  /// The mnemonic identifier of the offer being accepted.
  final String mnemonic;

  /// The device the offer is being accepted on.
  final Device device;

  /// The link of the offer being accepted.
  final String offerLink;

  /// The contact card sharing the identity of the accepting party.
  final ContactCard contactCard;

  /// The DID used by the accepting party to accept the offer.
  final String acceptOfferDid;
}
