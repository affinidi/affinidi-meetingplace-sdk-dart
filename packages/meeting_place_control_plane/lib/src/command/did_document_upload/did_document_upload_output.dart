import '../../core/model/did_document_hosting_record.dart';
import 'did_document_upload.dart' show UploadDidWebDocumentRequest;

/// The result returned when a did:web DID Document is uploaded.
typedef UploadDidWebDocumentResult = UploadDidWebDocumentCommandOutput;

/// Model that represents the output data returned from a successful execution
/// of [UploadDidWebDocumentRequest] operation.
class UploadDidWebDocumentCommandOutput {
  /// Creates a new instance of [UploadDidWebDocumentCommandOutput].
  UploadDidWebDocumentCommandOutput({required this.record});

  /// The record describing where the uploaded DID Document is hosted.
  final DidDocumentHostingRecord record;
}
