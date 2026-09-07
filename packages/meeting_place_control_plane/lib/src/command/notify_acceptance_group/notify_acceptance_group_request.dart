import '../../core/command/command.dart';
import 'notify_group_acceptance_result.dart';

/// Model that represents the request sent for the
/// [NotifyAcceptanceGroupRequest]
/// operation.
class NotifyAcceptanceGroupRequest
    extends DiscoveryCommand<NotifyGroupAcceptanceResult> {
  /// Creates a new instance of [NotifyAcceptanceGroupRequest].
  NotifyAcceptanceGroupRequest({
    required this.mnemonic,
    required this.acceptOfferDid,
    required this.offerLink,
    required this.senderInfo,
  });

  /// The mnemonic phrase identifying the group offer whose acceptance is
  /// notified.
  final String mnemonic;

  /// The DID of the group member who accepted the offer.
  final String acceptOfferDid;

  /// The link to the group offer that was accepted.
  final String offerLink;

  /// Sender info to be shown in the notification message.
  final String senderInfo;
}
