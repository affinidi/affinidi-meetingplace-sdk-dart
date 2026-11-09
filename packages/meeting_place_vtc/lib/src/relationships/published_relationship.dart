import '../meeting_place_vtc_sdk_exception.dart';

/// A relationship credential a community keeps in its trust graph: one
/// member's vouch for another, as `vtc/relationships/*` show it.
class PublishedRelationship {
  /// Creates a [PublishedRelationship].
  const PublishedRelationship({
    required this.id,
    required this.issuerDid,
    required this.subjectDid,
    required this.vrcDigestMultibase,
    this.createdAt,
  });

  /// Reads [item], an answer to `publish` or an item of `list`.
  ///
  /// Throws [MeetingPlaceVtcSDKException] when it is malformed.
  factory PublishedRelationship.read(Map<String, dynamic> item) {
    final id = item['id'];
    final issuerDid = item['issuerDid'];
    final subjectDid = item['subjectDid'];
    final digest = item['vrcDigestMultibase'];
    if (id is! String ||
        issuerDid is! String ||
        subjectDid is! String ||
        digest is! String) {
      throw MeetingPlaceVtcSDKException.invalidDocument(
        'malformed relationship',
      );
    }
    final createdAt = item['createdAt'];
    return PublishedRelationship(
      id: id,
      issuerDid: issuerDid,
      subjectDid: subjectDid,
      vrcDigestMultibase: digest,
      createdAt: createdAt is String ? DateTime.tryParse(createdAt) : null,
    );
  }

  /// The community's id of the edge, which `revoke` names.
  final String id;

  /// The member who vouched.
  final String issuerDid;

  /// The member vouched for.
  final String subjectDid;

  /// The digest of the credential, the same for the same credential.
  final String vrcDigestMultibase;

  /// When the community stored it: absent from an answer to `publish`.
  final DateTime? createdAt;
}
