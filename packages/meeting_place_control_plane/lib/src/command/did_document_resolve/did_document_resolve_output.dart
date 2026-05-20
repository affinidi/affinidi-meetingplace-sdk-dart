import 'package:ssi/ssi.dart';

/// Output returned after successfully resolving a did:web DID Document.
class ResolveDidDocumentCommandOutput {
  ResolveDidDocumentCommandOutput({required this.didDocument});

  final DidDocument didDocument;
}
