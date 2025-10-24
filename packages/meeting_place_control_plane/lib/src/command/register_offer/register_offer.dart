import 'package:didcomm/didcomm.dart';

import '../../core/command/command.dart';
import '../../core/device/device.dart';
import '../../core/offer_type.dart';
import '../../core/protocol/v_card/v_card.dart';
import 'register_offer_output.dart';

/// Model that represents the request sent for the [RegisterOfferCommand]
/// operation.
class RegisterOfferCommand
    extends DiscoveryCommand<RegisterOfferCommandOutput> {
  /// Creates a new instance of [RegisterOfferCommand].
  RegisterOfferCommand({
    required this.offerName,
    required this.vCard,
    required this.device,
    required this.type,
    required this.oobInvitationMessage,
    this.offerDescription,
    this.validUntil,
    this.maximumUsage,
    this.customPhrase,
    this.mediatorDid,
  });
  final String offerName;
  final VCard vCard;
  final Device device;
  final OfferType type;
  final PlainTextMessage oobInvitationMessage;

  final String? offerDescription;
  final DateTime? validUntil;
  final int? maximumUsage;
  final String? customPhrase;

  final String? mediatorDid;
}
