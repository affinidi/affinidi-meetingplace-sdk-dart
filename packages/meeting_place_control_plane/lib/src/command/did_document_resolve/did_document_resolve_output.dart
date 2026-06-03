import 'package:ssi/ssi.dart';

/// Model that represents the output data returned from a successful execution
/// of ResolveDidWebDocumentCommand operation.
class ResolveDidWebDocumentCommandOutput {
  /// Creates a new instance of [ResolveDidWebDocumentCommandOutput].
  ResolveDidWebDocumentCommandOutput({required this.didDocument});

  final DidDocument didDocument;
}
