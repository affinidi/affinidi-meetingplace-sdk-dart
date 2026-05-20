import '../../core/command/command.dart';
import '../../core/model/did_web_proof.dart';
import 'did_document_upload_output.dart';

/// Command to upload (create) a new did:web DID Document on the Control Plane.
///
/// [controlProof] is a detached JWS signed by the `controlDid` key.
/// [proof] is a detached JWS signed by the new `#auth` key inside
/// [didDocument]. Both are required by the MPX Matrix Integration ADR.
class UploadDidDocumentCommand
    extends DiscoveryCommand<UploadDidDocumentCommandOutput> {
  UploadDidDocumentCommand({
    required this.didDocument,
    required this.controlProof,
    required this.proof,
  });

  final Map<String, dynamic> didDocument;
  final DidWebProof controlProof;
  final DidWebProof proof;
}
