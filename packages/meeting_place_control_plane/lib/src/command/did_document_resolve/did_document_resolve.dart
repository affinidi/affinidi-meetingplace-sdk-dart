import '../../core/command/command.dart';
import 'did_document_resolve_output.dart';

/// Command to resolve a did:web DID Document using the SSI DID resolver.
///
/// [did] must be the full did:web DID string,
/// e.g. `did:web:<server_name>:user:<segment>`.
class ResolveDidDocumentCommand
    extends DiscoveryCommand<ResolveDidDocumentCommandOutput> {
  ResolveDidDocumentCommand({required this.did});

  final String did;
}

