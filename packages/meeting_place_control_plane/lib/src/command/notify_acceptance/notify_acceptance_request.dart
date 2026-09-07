import '../../core/command/command.dart';
import 'notify_acceptance_result.dart';

/// Model that represents the request sent for the [NotifyAcceptanceRequest]
/// operation.
class NotifyAcceptanceRequest extends DiscoveryCommand<NotifyAcceptanceResult> {
  /// Creates a new instance of [NotifyAcceptanceRequest].
  NotifyAcceptanceRequest({
    required this.mnemonic,
    required this.acceptOfferDid,
    required this.offerLink,
    required this.senderInfo,
  });

  /// The mnemonic phrase identifying the offer whose acceptance is notified.
  final String mnemonic;

  /// The DID of the party who accepted the offer.
  final String acceptOfferDid;

  /// The link to the offer that was accepted.
  final String offerLink;

  /// Sender info to be shown in the notification message.
  final String senderInfo;
}
