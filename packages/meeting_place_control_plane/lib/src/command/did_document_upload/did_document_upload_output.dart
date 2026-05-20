import '../../core/model/did_document_hosting_record.dart';

/// Output returned after successfully uploading a did:web DID Document.
class UploadDidDocumentCommandOutput {
  UploadDidDocumentCommandOutput({required this.record});

  final DidDocumentHostingRecord record;
}
