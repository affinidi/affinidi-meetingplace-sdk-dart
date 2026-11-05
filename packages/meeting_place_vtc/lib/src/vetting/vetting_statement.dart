import '../credentials/credential_fields.dart';
import 'vetting_requirements.dart';

/// A vetter's statement that they vetted an applicant: a DTG
/// `StatementCredential` under the predicate [VettingStatement.predicate],
/// e.g.
///
/// ```json
/// {
///   "type": ["VerifiableCredential", "DTGCredential", "StatementCredential"],
///   "issuer": "<vetter DID>",
///   "validFrom": "…",
///   "validUntil": "…",
///   "taskContext": "<vetting/session document id>",
///   "taskDigestMultibase": "z…",
///   "credentialSubject": {
///     "id": "<applicant's join DID>",
///     "predicate": "https://registry.trustoverip.org/dtg/vsc/vetted/1",
///     "object": {"value": {
///       "community": "<community DID>", "method": "inPerson",
///       "documentClasses": ["passport"], "claimsVerified": ["name.legal"],
///       "livenessConfirmed": true, "identityCommitment": "z…",
///       "cardDigestMultibase": "z…", "declaredRelationship": "none"
///     }}
///   }
/// }
/// ```
///
/// Reading one checks its shape only, not its proof.
class VettingStatement {
  const VettingStatement._({
    required this.credential,
    required this.vetterDid,
    required this.applicantDid,
    required this.community,
    required this.method,
    required this.documentClasses,
    required this.claimsVerified,
    required this.livenessConfirmed,
    required this.identityCommitment,
    required this.cardDigestMultibase,
    required this.declaredRelationship,
    required this.validFrom,
    required this.validUntil,
    required this.taskContext,
    required this.taskDigestMultibase,
  });

  /// The predicate of a vetting statement.
  static const predicate = 'https://registry.trustoverip.org/dtg/vsc/vetted/1';

  /// The VC type of a vetting statement.
  static const type = 'StatementCredential';

  /// Reads [credential] as a vetter's statement, or returns null when it is
  /// none: another kind of credential, a community's own check (which has
  /// no identity commitment), or a member missing or malformed.
  static VettingStatement? read(Map<String, dynamic> credential) {
    final subject = credential['credentialSubject'];
    if (!credentialTypes(credential).contains(type) ||
        subject is! Map ||
        subject['predicate'] != predicate) {
      return null;
    }
    final object = subject['object'];
    final value = object is Map ? object['value'] : null;
    if (value is! Map) return null;

    final issuer = credentialIssuer(credential);
    final applicant = subject['id'];
    final community = value['community'];
    final method = VettingMethod.values.asNameMap()[value['method']];
    final relationship = VettingRelationship.values
        .asNameMap()[value['declaredRelationship']];
    final commitment = value['identityCommitment'];
    final cardDigest = value['cardDigestMultibase'];
    final validFrom = DateTime.tryParse('${credential['validFrom']}');
    final validUntil = DateTime.tryParse('${credential['validUntil']}');
    final taskContext = credential['taskContext'];
    final taskDigest = credential['taskDigestMultibase'];
    if (issuer == null ||
        applicant is! String ||
        community is! String ||
        method == null ||
        relationship == null ||
        commitment is! String ||
        cardDigest is! String ||
        validFrom == null ||
        validUntil == null ||
        taskContext is! String ||
        taskDigest is! String) {
      return null;
    }
    return VettingStatement._(
      credential: credential,
      vetterDid: issuer,
      applicantDid: applicant,
      community: community,
      method: method,
      documentClasses: _strings(value['documentClasses']),
      claimsVerified: _strings(value['claimsVerified']),
      livenessConfirmed: value['livenessConfirmed'] == true,
      identityCommitment: commitment,
      cardDigestMultibase: cardDigest,
      declaredRelationship: relationship,
      validFrom: validFrom,
      validUntil: validUntil,
      taskContext: taskContext,
      taskDigestMultibase: taskDigest,
    );
  }

  /// The credential as the vetter issued it.
  final Map<String, dynamic> credential;

  /// The vetter's DID, the statement's issuer.
  final String vetterDid;

  /// The applicant's join DID, the statement's subject.
  final String applicantDid;

  /// The community the applicant was vetted for.
  final String community;

  /// How the vetter met the applicant.
  final VettingMethod method;

  /// The documentation the vetter relied on, e.g. `passport`.
  final List<String> documentClasses;

  /// The claims the vetter verified, e.g. `name.legal`.
  final List<String> claimsVerified;

  /// Whether the vetter saw the applicant live.
  final bool livenessConfirmed;

  /// The commitment to the claims the applicant's vetting card carried.
  final String identityCommitment;

  /// The digest of the vetting card the vetter checked.
  final String cardDigestMultibase;

  /// How the vetter declares they know the applicant.
  final VettingRelationship declaredRelationship;

  /// From when the statement holds.
  final DateTime validFrom;

  /// Until when the statement holds.
  final DateTime validUntil;

  /// The id of the `vetting/session` document it was made in.
  final String taskContext;

  /// The digest of that session document.
  final String taskDigestMultibase;

  static List<String> _strings(Object? json) =>
      json is List ? json.whereType<String>().toList() : const [];
}
