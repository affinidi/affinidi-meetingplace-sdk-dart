import '../../core/command/command.dart';
import '../../core/model/did_web_proof.dart';
import 'did_document_upload_output.dart';

/// Model that represents the request sent for the [UploadDidDocumentCommand]
/// operation.
class UploadDidDocumentCommand
    extends DiscoveryCommand<UploadDidDocumentCommandOutput> {
  /// Creates a new instance of [UploadDidDocumentCommand].
  ///
  /// **Parameters:**
  /// - [didDocument]: The DID Document JSON map. Must contain an `id` field
  /// set to a valid `did:web` DID.
  /// - [controlProof]: Detached JWS signed by the `controlDid` key.
  /// - [proof]: Detached JWS signed by the `#auth` key inside [didDocument].
  /// Both proofs are required by the MPX Matrix Integration ADR.
  UploadDidDocumentCommand({
    required this.didDocument,
    required this.controlProof,
    required this.proof,
  });

  final Map<String, dynamic> didDocument;
  final DidWebProof controlProof;
  final DidWebProof proof;
}
