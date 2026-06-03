import 'package:json_annotation/json_annotation.dart';

part 'did_document_hosting_record.g.dart';

/// Response returned after uploading a did:web DID Document
/// on the Control Plane API.
///
/// The [didDocUrl] is the public URL at which the DID Document can be resolved
/// via standard did:web resolution semantics.
@JsonSerializable()
class DidDocumentHostingRecord {
  DidDocumentHostingRecord({
    required this.did,
    required this.segment,
    required this.didDocUrl,
  });

  factory DidDocumentHostingRecord.fromJson(Map<String, dynamic> json) =>
      _$DidDocumentHostingRecordFromJson(json);

  /// The full did:web DID, e.g. `did:web:host:user:alice`.
  final String did;

  /// The last segment of the DID, used in the resolution URL path.
  final String segment;

  /// The public URL at which the DID Document is hosted.
  final String didDocUrl;

  Map<String, dynamic> toJson() => _$DidDocumentHostingRecordToJson(this);
}
