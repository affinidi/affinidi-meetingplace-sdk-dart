import '../../core/model/did_document_hosting_record.dart';
import 'upload_did_web_document_request.dart' show UploadDidWebDocumentRequest;

/// The result returned when a did:web DID Document is uploaded.
/// Model that represents the output data returned from a successful execution
/// of [UploadDidWebDocumentRequest] operation.
class UploadDidWebDocumentResult {
  /// Creates a new instance of [UploadDidWebDocumentResult].
  UploadDidWebDocumentResult({required this.record});

  /// The record describing where the uploaded DID Document is hosted.
  final DidDocumentHostingRecord record;
}
