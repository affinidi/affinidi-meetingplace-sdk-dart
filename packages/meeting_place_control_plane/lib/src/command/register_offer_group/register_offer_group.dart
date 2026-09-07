import 'package:didcomm/didcomm.dart';

import '../../core/command/command.dart';
import '../../core/device/device.dart';
import '../../core/protocol/contact_card/contact_card.dart';
import 'register_offer_group_output.dart';

/// Model that represents the request sent for the [RegisterOfferGroupCommand]
/// operation.
class RegisterOfferGroupCommand
    extends DiscoveryCommand<RegisterOfferGroupCommandOutput> {
  /// Creates a new instance of [RegisterOfferGroupCommand].
  RegisterOfferGroupCommand({
    required this.offerName,
    required this.offerDescription,
    required this.contactCard,
    required this.device,
    required this.oobInvitationMessage,
    required this.adminDid,
    this.validUntil,
    this.maximumUsage,
    this.customMnemonic,
    this.mediatorDid,
    this.mediatorEndpoint,
    this.mediatorWSSEndpoint,
    this.metadata,
  });
  /// The human-readable name of the group offer.
  final String offerName;

  /// A description of the group offer shown to potential members.
  final String offerDescription;

  /// The contact card shared with users who join the group offer.
  final ContactCard contactCard;

  /// The device used to register the group offer.
  final Device device;

  /// The out-of-band DIDComm invitation message embedded in the group offer.
  final PlainTextMessage oobInvitationMessage;

  /// The point in time after which the group offer expires, when set.
  final DateTime? validUntil;

  /// The maximum number of times the group offer can be accepted, when set.
  final int? maximumUsage;

  /// A custom mnemonic phrase to assign to the group offer instead of a
  /// generated one, when set.
  final String? customMnemonic;

  /// The DID of the mediator to use for the group offer, overriding the SDK
  /// default mediator, when set.
  final String? mediatorDid;

  /// The mediator's HTTP endpoint, when set.
  final String? mediatorEndpoint;

  /// The mediator's WebSocket endpoint, when set.
  final String? mediatorWSSEndpoint;

  /// Arbitrary metadata attached to the group offer, when set.
  final String? metadata;

  /// The DID of the group admin managing the group offer.
  final String adminDid;
}
