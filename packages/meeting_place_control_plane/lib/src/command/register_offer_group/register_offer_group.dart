import 'package:didcomm/didcomm.dart';

import '../../core/command/command.dart';
import '../../core/device/device.dart';
import '../../protocol/v_card/v_card.dart';
import 'register_offer_group_output.dart';

/// Model that represents the request sent for the [RegisterOfferGroupCommand]
/// operation.
class RegisterOfferGroupCommand
    extends DiscoveryCommand<RegisterOfferGroupCommandOutput> {
  /// Creates a new instance of [RegisterOfferGroupCommand].
  RegisterOfferGroupCommand({
    required this.offerName,
    required this.vCard,
    required this.device,
    required this.oobInvitationMessage,
    required this.adminDid,
    required this.adminPublicKey,
    required this.adminReencryptionKey,
    this.offerDescription,
    this.validUntil,
    this.maximumUsage,
    this.customPhrase,
    this.mediatorDid,
    this.mediatorEndpoint,
    this.mediatorWSSEndpoint,
    this.metadata,
  });
  final String offerName;
  final VCard vCard;
  final Device device;
  final PlainTextMessage oobInvitationMessage;

  final String? offerDescription;
  final DateTime? validUntil;
  final int? maximumUsage;
  final String? customPhrase;

  final String? mediatorDid;
  final String? mediatorEndpoint;
  final String? mediatorWSSEndpoint;

  final String? metadata;

  final String adminDid;
  final String adminPublicKey;
  final String adminReencryptionKey;
}
