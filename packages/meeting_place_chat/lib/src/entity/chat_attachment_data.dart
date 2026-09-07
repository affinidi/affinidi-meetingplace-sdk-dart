/// A transport-agnostic data container for a `ChatAttachment`.
///
/// Mirrors the data representation options supported by DIDComm attachments
/// but without any transport-layer dependencies.
class ChatAttachmentData {
  /// Creates a new [ChatAttachmentData].
  ///
  /// All parameters are optional; a real attachment typically supplies
  /// exactly one of [base64], [json], or [links].
  ChatAttachmentData({this.jws, this.hash, this.links, this.base64, this.json});

  /// Deserialises a [ChatAttachmentData] from a JSON map.
  factory ChatAttachmentData.fromJson(Map<String, dynamic> json) {
    return ChatAttachmentData(
      jws: json['jws'] as String?,
      hash: json['hash'] as String?,
      links: (json['links'] as List<dynamic>?)
          ?.map((e) => Uri.parse(e as String))
          .toList(),
      base64: json['base64'] as String?,
      json: json['json'] as String?,
    );
  }

  /// A JWS (JSON Web Signature) for the attachment content.
  final String? jws;

  /// Multi-hash integrity check for referenced content.
  final String? hash;

  /// URIs where the content can be fetched.
  final List<Uri>? links;

  /// Base64url-encoded inline content.
  final String? base64;

  /// Inline JSON content.
  final String? json;

  /// Serialises this [ChatAttachmentData] to a JSON map, omitting any unset
  /// fields.
  Map<String, dynamic> toJson() {
    final result = <String, dynamic>{};
    if (jws != null) result['jws'] = jws;
    if (hash != null) result['hash'] = hash;
    if (links != null) {
      result['links'] = links!.map((e) => e.toString()).toList();
    }
    if (base64 != null) result['base64'] = base64;
    if (json != null) result['json'] = json;
    return result;
  }
}
