import '../../core/model/did_document_hosting_record.dart';

/// Model that represents the output data returned from a successful execution
/// of [UploadDidDocumentCommandOutput] operation.
class UploadDidDocumentCommandOutput {
  /// Creates a new instance of [UploadDidDocumentCommandOutput].
  UploadDidDocumentCommandOutput({required this.record});

  final DidDocumentHostingRecord record;
}
