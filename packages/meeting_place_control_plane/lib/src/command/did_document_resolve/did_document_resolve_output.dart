import 'package:ssi/ssi.dart';

/// Model that represents the output data returned from a successful execution
/// of [ResolveDidDocumentCommandOutput] operation.
class ResolveDidDocumentCommandOutput {
  /// Creates a new instance of [ResolveDidDocumentCommandOutput].
  ResolveDidDocumentCommandOutput({required this.didDocument});

  final DidDocument didDocument;
}
