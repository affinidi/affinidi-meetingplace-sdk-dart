import '../../core/model/did_document_hosting_record.dart';
import 'did_document_upload.dart' show UploadDidWebDocumentCommand;

/// Model that represents the output data returned from a successful execution
/// of [UploadDidWebDocumentCommand] operation.
class UploadDidWebDocumentCommandOutput {
  /// Creates a new instance of [UploadDidWebDocumentCommandOutput].
  UploadDidWebDocumentCommandOutput({required this.record});

  final DidDocumentHostingRecord record;
}
