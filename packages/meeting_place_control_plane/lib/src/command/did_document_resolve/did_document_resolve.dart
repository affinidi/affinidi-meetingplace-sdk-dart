import '../../core/command/command.dart';
import 'did_document_resolve_output.dart';

/// Model that represents the request sent for the
/// [ResolveDidWebDocumentCommand] operation.
class ResolveDidWebDocumentCommand
    extends DiscoveryCommand<ResolveDidWebDocumentCommandOutput> {
  /// Creates a new instance of [ResolveDidWebDocumentCommand].
  ///
  /// **Parameters:**
  /// - [did]: The full did:web DID string,
  /// e.g. `did:web:<server_name>:user:<segment>`.
  ResolveDidWebDocumentCommand({required this.did});

  final String did;

  @override
  bool get requiresBootstrap => false;

  @override
  bool get requiresAuthentication => false;
}
