import '../../core/command/command.dart';
import 'did_document_resolve_output.dart';

/// Model that represents the request sent for the [ResolveDidDocumentCommand]
/// operation.
class ResolveDidDocumentCommand
    extends DiscoveryCommand<ResolveDidDocumentCommandOutput> {
  /// Creates a new instance of [ResolveDidDocumentCommand].
  ///
  /// **Parameters:**
  /// - [did]: The full did:web DID string,
  /// e.g. `did:web:<server_name>:user:<segment>`.
  ResolveDidDocumentCommand({required this.did});

  final String did;
}
