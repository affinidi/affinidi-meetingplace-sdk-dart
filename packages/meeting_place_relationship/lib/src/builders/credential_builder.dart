import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';

import '../models/credential_constants.dart';
import '../models/r_card/r_card_subject.dart';
import '../models/vrc/vrc_credential_subject.dart';

/// Builds and signs relationship credentials (R-Card and VRC).
///
/// All methods are static. Callers provide the required cryptographic
/// material via [DidManager]; this class performs no key management of
/// its own.
class CredentialBuilder {
  CredentialBuilder._();

  /// Builds and signs a Relationship Card (R-Card) Verifiable Credential.
  ///
  /// Uses W3C Data Model v2 with an ecdsa-jcs-2019 (Data Integrity) proof.
  /// - [subjectDid] — DID of the credential subject.
  /// - [subject] — Parsed contact fields to embed as a jCard in the VC.
  /// - [issuerDidManager] — [DidManager] used to sign the credential.
  static Future<VerifiableCredential> buildRCard({
    required String issuerDid,
    required String subjectDid,
    required RCardSubject subject,
    required DidManager issuerDidManager,
  }) async {
    final unsignedCredential = VcDataModelV2(
      context: JsonLdContext.fromJson([
        dmV2ContextUrl,
        RelationshipCredentialConstants.dataIntegrityV2Context,
        RelationshipCredentialConstants.contextRCard,
      ]),
      id: Uri.parse('urn:uuid:${const Uuid().v4()}'),
      issuer: Issuer.uri(issuerDid),
      type: {
        RelationshipCredentialConstants.typeVerifiableCredential,
        RelationshipCredentialConstants.typeRCard,
      },
      validFrom: DateTime.now().toUtc(),
      credentialSubject: [
        CredentialSubject.fromJson({
          'id': subjectDid,
          'card': _toJCard(subject),
        }),
      ],
    );

    return _sign(unsignedCredential, issuerDidManager);
  }

  /// Builds and signs a Verifiable Relationship Credential (VRC).
  ///
  /// Uses W3C Data Model v2 with an ecdsa-jcs-2019 (Data Integrity) proof.
  ///
  /// - [issuerDid] — DID of the issuer (the party signing the credential).
  /// - [subject] — The two-party relationship subject (`from` / `to`).
  /// - [issuerDidManager] — [DidManager] used to sign the credential.
  static Future<VerifiableCredential> buildVrc({
    required String issuerDid,
    required VrcCredentialSubject subject,
    required DidManager issuerDidManager,
  }) async {
    final unsignedCredential = VcDataModelV2(
      context: JsonLdContext.fromJson([
        dmV2ContextUrl,
        RelationshipCredentialConstants.dataIntegrityV2Context,
        RelationshipCredentialConstants.contextVrc,
      ]),
      credentialSchema: [
        CredentialSchema(
          id: Uri.parse(
            RelationshipCredentialConstants.contextVrc.replaceFirst(
              '.jsonld',
              '.json',
            ),
          ),
          type: 'JsonSchemaValidator2018',
        ),
      ],
      id: Uri.parse('urn:uuid:${const Uuid().v4()}'),
      issuer: Issuer.uri(issuerDid),
      type: {
        RelationshipCredentialConstants.typeVerifiableCredential,
        RelationshipCredentialConstants.typeRelationshipCredential,
      },
      validFrom: DateTime.now().toUtc(),
      credentialSubject: [CredentialSubject.fromJson(subject.toJson())],
    );

    return _sign(unsignedCredential, issuerDidManager);
  }

  /// Signs [unsigned] using the first assertion method key from [manager].
  ///
  /// Throws [StateError] if [manager] has no assertion method keys.
  static Future<VerifiableCredential> _sign(
    VcDataModelV2 unsigned,
    DidManager manager,
  ) async {
    if (manager.assertionMethod.isEmpty) {
      throw StateError(
        'DidManager has no assertionMethod keys available for signing',
      );
    }
    final suite = LdVcDm2Suite();
    final signer = await manager.getSigner(manager.assertionMethod.first);
    return suite.issue(
      unsignedData: unsigned,
      proofGenerator: DataIntegrityEcdsaJcsGenerator(signer: signer),
    );
  }

  /// Converts an [RCardSubject] to a jCard-compatible list structure.
  ///
  /// Only non-empty fields are included. The output follows the jCard
  /// format: `['vcard', [[field, {}, 'text', value], ...]]`.
  static List<Object> _toJCard(RCardSubject subject) {
    final fields = <String, String?>{
      'firstName': subject.firstName,
      'lastName': subject.lastName,
      'email': subject.email,
      'phone': subject.phone,
      'profilePic': subject.profilePic,
      'company': subject.company,
      'position': subject.position,
      'social': subject.social,
      'website': subject.website,
    };

    final entries = fields.entries
        .where((e) => (e.value ?? '').trim().isNotEmpty)
        .map((e) => [e.key, const <String, dynamic>{}, 'text', e.value])
        .toList(growable: false);

    return ['vcard', entries];
  }
}
