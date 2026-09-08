import '../../core/command/command.dart';
import '../../core/model/did_web_proof.dart';
import 'upload_did_web_document_result.dart';

/// Model that represents the request sent for the [UploadDidWebDocumentRequest]
/// operation.
class UploadDidWebDocumentRequest
    extends DiscoveryCommand<UploadDidWebDocumentResult> {
  /// Creates a new instance of [UploadDidWebDocumentRequest].
  ///
  /// The [didDocument] is the DID Document JSON map, and must contain an
  /// `id` field set to a valid `did:web` DID. The [controlProof] is a
  /// compact JWS with an embedded payload, signed by the `controlDid` key.
  /// The [proof] is a compact JWS with an embedded payload, signed by the
  /// `#auth` key inside [didDocument].
  UploadDidWebDocumentRequest({
    required this.didDocument,
    required this.controlProof,
    required this.proof,
  });

  /// The DID Document JSON map, with an `id` field set to a valid
  /// `did:web` DID.
  final Map<String, dynamic> didDocument;

  /// A compact JWS with an embedded payload, signed by the `controlDid` key.
  final DidWebProof controlProof;

  /// A compact JWS with an embedded payload, signed by the `#auth` key
  /// inside [didDocument].
  final DidWebProof proof;
}
