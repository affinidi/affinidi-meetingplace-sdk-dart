import '../../core/command/command.dart';
import 'query_offer_output.dart';

/// Model that represents the request sent for the [QueryOfferRequest]
/// operation.
class QueryOfferRequest extends DiscoveryCommand<QueryOfferCommandOutput> {
  /// Creates a new instance of [QueryOfferRequest].
  QueryOfferRequest({required this.mnemonic});

  /// The mnemonic phrase identifying the offer to query.
  final String mnemonic;
}
