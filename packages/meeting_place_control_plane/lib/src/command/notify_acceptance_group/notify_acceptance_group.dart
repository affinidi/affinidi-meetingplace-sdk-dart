import '../../core/command/command.dart';
import 'notify_acceptance_output.dart';

/// Model that represents the request sent for the [NotifyAcceptanceGroupCommand]
/// operation.
class NotifyAcceptanceGroupCommand
    extends DiscoveryCommand<NotifyAcceptanceGroupCommandOutput> {
  /// Creates a new instance of [NotifyAcceptanceGroupCommand].
  NotifyAcceptanceGroupCommand({
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
