import 'package:didcomm/didcomm.dart';

import '../../core/command/command.dart';
import '../../core/device/device.dart';
import '../../core/offer_type.dart';
import '../../core/protocol/contact_card/contact_card.dart';
import '../../core/protocol/transport.dart';
import 'register_offer_result.dart';

/// Model that represents the request sent for the [RegisterOfferRequest]
/// operation.
class RegisterOfferRequest extends DiscoveryCommand<RegisterOfferResult> {
  /// Creates a new instance of [RegisterOfferRequest].
  RegisterOfferRequest({
    required this.offerName,
    required this.offerDescription,
    required this.contactCard,
    required this.device,
    required this.type,
    required this.oobInvitationMessage,
    required this.transport,
    this.validUntil,
    this.maximumUsage,
    this.customMnemonic,
    this.mediatorDid,
    this.score,
  });

  /// The human-readable name of the offer.
  final String offerName;

  /// A description of the offer shown to potential recipients.
  final String offerDescription;

  /// The contact card shared with users who accept the offer.
  final ContactCard contactCard;

  /// The device used to register the offer.
  final Device device;

  /// The type of offer being registered.
  final OfferType type;

  /// The out-of-band DIDComm invitation message embedded in the offer.
  final PlainTextMessage oobInvitationMessage;

  /// The point in time after which the offer expires, when set.
  final DateTime? validUntil;

  /// The maximum number of times the offer can be accepted, when set.
  final int? maximumUsage;

  /// A custom mnemonic phrase to assign to the offer instead of a generated
  /// one, when set.
  final String? customMnemonic;

  /// The DID of the mediator to use for the offer, overriding the SDK
  /// default mediator, when set.
  final String? mediatorDid;

  /// Transport selected by the publisher.
  final OfferTransport transport;

  /// The initial score assigned to the offer, when set.
  final int? score;
}
