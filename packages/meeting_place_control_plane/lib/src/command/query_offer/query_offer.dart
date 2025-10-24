import '../../core/command/command.dart';
import 'query_offer_output.dart';

/// Model that represents the request sent for the [QueryOfferCommand]
/// operation.
class QueryOfferCommand extends DiscoveryCommand<QueryOfferCommandOutput> {
  /// Creates a new instance of [QueryOfferCommand].
  QueryOfferCommand({required this.mnemonic});
  final String mnemonic;
}
