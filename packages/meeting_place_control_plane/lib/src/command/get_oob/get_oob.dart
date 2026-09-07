import '../../core/command/command.dart';
import 'get_oob_output.dart';

/// Model that represents the request sent for the [GetOobRequest]
/// operation.
class GetOobRequest extends DiscoveryCommand<GetOobCommandOutput> {
  /// Creates a new instance of [GetOobRequest].
  GetOobRequest({required this.oobId});

  /// The identifier of the out-of-band invitation to retrieve.
  final String oobId;
}
