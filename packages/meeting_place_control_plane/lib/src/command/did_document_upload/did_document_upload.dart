import '../../core/command/command.dart';
import 'did_document_upload_output.dart';

class DidDocumentUploadCommand
    extends DiscoveryCommand<DidDocumentUploadCommandOutput> {
  DidDocumentUploadCommand({
    required this.didDocument,
    required this.controlProof,
    required this.proof,
  });

  final Map<String, dynamic> didDocument;
  final Map<String, dynamic> controlProof;
  final Map<String, dynamic> proof;
}
