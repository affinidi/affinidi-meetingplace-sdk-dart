import '../../core/command/command.dart';
import 'notify_acceptance_output.dart';

/// Model that represents the request sent for the [NotifyAcceptanceCommand]
/// operation.
class NotifyAcceptanceCommand
    extends DiscoveryCommand<NotifyAcceptanceCommandOutput> {
  /// Creates a new instance of [NotifyAcceptanceCommand].
  NotifyAcceptanceCommand({
    required this.mnemonic,
    required this.acceptOfferDid,
    required this.offerLink,
    required this.senderInfo,
  });
  final String mnemonic;
  final String acceptOfferDid;
  final String offerLink;
  final String senderInfo;
}
