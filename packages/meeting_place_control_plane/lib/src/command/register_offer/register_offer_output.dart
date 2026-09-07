import 'package:didcomm/didcomm.dart';

import 'register_offer.dart' show RegisterOfferCommand;

/// Model that represents the output data returned from a successful execution
/// of [RegisterOfferCommand] operation.
class RegisterOfferCommandOutput {
  /// Creates a new instance of [RegisterOfferCommandOutput].
  RegisterOfferCommandOutput({
    required this.mediatorDid,
    required this.offerName,
    required this.offerLink,
    required this.mnemonic,
    required this.didcommMessage,
    required this.expiresAt,
    required this.maximumUsage,
    this.offerDescription,
    this.score,
  });
  /// The DID of the mediator handling the registered offer.
  final String mediatorDid;

  /// The name of the registered offer.
  final String offerName;

  /// The shareable link to the registered offer.
  final String offerLink;

  /// The mnemonic phrase generated for the registered offer.
  final String mnemonic;

  /// The out-of-band DIDComm invitation message embedded in the offer.
  final PlainTextMessage didcommMessage;

  /// The point in time after which the offer expires, when set.
  final DateTime? expiresAt;

  /// The maximum number of times the offer can be accepted, when set.
  final int? maximumUsage;

  /// The description of the registered offer, when provided.
  final String? offerDescription;

  /// The score assigned to the registered offer, when provided.
  final int? score;
}
