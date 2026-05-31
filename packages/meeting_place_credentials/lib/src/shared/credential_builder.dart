import 'package:ssi/ssi.dart';

import '../rcard/builder/r_card_builder.dart';
import '../rcard/model/r_card_subject.dart';
import '../vrc/builder/vrc_builder.dart';
import '../vrc/model/vrc_credential_subject.dart';
import '../zkp/builder/liveness_vc_builder.dart';
import '../zkp/model/liveness_evidence.dart';

/// Builds and signs credentials (R-Card and VRC).
///
/// This is the public facade for credential building. Internally delegates to
/// [RCardBuilder] and [VrcBuilder]. Add new credential types by creating a new
/// dedicated builder class rather than expanding this class.
class CredentialBuilder {
  CredentialBuilder._();

  /// Builds and signs a Relationship Card (R-Card) Verifiable Credential.
  ///
  /// Uses W3C Data Model v2 with an ecdsa-jcs-2019 (Data Integrity) proof.
  /// Contact data is embedded as an RFC 7095 jCard in the credential subject.
  ///
  /// - [issuerDid] — DID of the issuer.
  /// - [subjectDid] — DID of the credential subject.
  /// - [subject] — Parsed contact fields to embed as a jCard in the VC.
  /// - [issuerDidManager] — [DidManager] used to sign the credential.
  static Future<VerifiableCredential> buildRCard({
    required String issuerDid,
    required String subjectDid,
    required RCardSubject subject,
    required DidManager issuerDidManager,
  }) => RCardBuilder.build(
    issuerDid: issuerDid,
    subjectDid: subjectDid,
    subject: subject,
    issuerDidManager: issuerDidManager,
  );

  /// Builds and signs a Verifiable Relationship Credential (VRC).
  ///
  /// Uses W3C Data Model v2 with an ecdsa-jcs-2019 (Data Integrity) proof.
  ///
  /// - [issuerDid] — DID of the issuer (the party signing the credential).
  /// - [subject] — The two-party credential subject (`from` / `to`).
  /// - [issuerDidManager] — [DidManager] used to sign the credential.
  static Future<VerifiableCredential> buildVrc({
    required String issuerDid,
    required VrcCredentialSubject subject,
    required DidManager issuerDidManager,
  }) => VrcBuilder.build(
    issuerDid: issuerDid,
    subject: subject,
    issuerDidManager: issuerDidManager,
  );

  /// Builds and signs a Liveness Verifiable Credential.
  ///
  /// Uses W3C Data Model v2 with a Data Integrity proof. Liveness claims are
  /// provider-neutral and stored in [LivenessCredentialSubject].
  static Future<VerifiableCredential> buildLiveness({
    required String issuerDid,
    required String holderDid,
    required LivenessEvidence evidence,
    required DidManager issuerDidManager,
    Duration validFor = const Duration(days: 5),
  }) => LivenessVcBuilder.build(
    issuerDid: issuerDid,
    holderDid: holderDid,
    evidence: evidence,
    issuerDidManager: issuerDidManager,
    validFor: validFor,
  );
}
