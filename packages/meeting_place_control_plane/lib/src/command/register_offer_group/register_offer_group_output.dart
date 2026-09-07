import 'package:didcomm/didcomm.dart';

import 'register_offer_group.dart' show RegisterOfferGroupCommand;

/// Model that represents the output data returned from a successful execution
/// of [RegisterOfferGroupCommand] operation.
class RegisterOfferGroupCommandOutput {
  /// Creates a new instance of [RegisterOfferGroupCommandOutput].
  RegisterOfferGroupCommandOutput({
    required this.groupId,
    required this.groupDid,
    required this.mediatorDid,
    required this.offerLink,
    required this.mnemonic,
    required this.expiresAt,
    required this.maximumUsage,
    required this.oobInvitationMessage,
  });
  final String groupId;
  final String groupDid;
  final String mediatorDid;
  final String offerLink;
  final String mnemonic;
  final DateTime? expiresAt;
  final int? maximumUsage;
  final PlainTextMessage oobInvitationMessage;
}
