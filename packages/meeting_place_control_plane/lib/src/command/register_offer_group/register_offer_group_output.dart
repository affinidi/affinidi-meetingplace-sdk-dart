import 'package:didcomm/didcomm.dart';

import 'register_offer_group.dart' show RegisterOfferGroupCommand;

/// The result returned when a group offer is registered successfully.
typedef RegisterOfferGroupResult = RegisterOfferGroupCommandOutput;

/// Model that represents the output data returned from a successful execution
/// of [RegisterOfferGroupCommand] operation.
class RegisterOfferGroupCommandOutput {
  /// Creates a new instance of [RegisterOfferGroupCommandOutput].
  RegisterOfferGroupCommandOutput({
    required this.groupId,
    required this.mediatorDid,
    required this.offerLink,
    required this.mnemonic,
    required this.expiresAt,
    required this.maximumUsage,
    required this.oobInvitationMessage,
  });

  /// The unique identifier of the registered group offer.
  final String groupId;

  /// The DID of the mediator handling the registered group offer.
  final String mediatorDid;

  /// The shareable link to the registered group offer.
  final String offerLink;

  /// The mnemonic phrase generated for the registered group offer.
  final String mnemonic;

  /// The point in time after which the group offer expires, when set.
  final DateTime? expiresAt;

  /// The maximum number of times the group offer can be accepted, when set.
  final int? maximumUsage;

  /// The out-of-band DIDComm invitation message embedded in the group offer.
  final PlainTextMessage oobInvitationMessage;
}
