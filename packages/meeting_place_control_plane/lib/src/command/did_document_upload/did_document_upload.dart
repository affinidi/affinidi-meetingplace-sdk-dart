import '../../core/command/command.dart';
import '../../core/model/did_web_proof.dart';
import 'did_document_upload_output.dart';

/// Model that represents the request sent for the [UploadDidWebDocumentCommand]
/// operation.
class UploadDidWebDocumentCommand
    extends DiscoveryCommand<UploadDidWebDocumentCommandOutput> {
  /// Creates a new instance of [UploadDidWebDocumentCommand].
  ///
  /// The [didDocument] is the DID Document JSON map, and must contain an
  /// `id` field set to a valid `did:web` DID. The [controlProof] is a
  /// compact JWS with an embedded payload, signed by the `controlDid` key.
  /// The [proof] is a compact JWS with an embedded payload, signed by the
  /// `#auth` key inside [didDocument].
  UploadDidWebDocumentCommand({
    required this.didDocument,
    required this.controlProof,
    required this.proof,
  });

  final Map<String, dynamic> didDocument;
  final DidWebProof controlProof;
  final DidWebProof proof;
}
