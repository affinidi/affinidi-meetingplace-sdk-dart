import 'package:ssi/ssi.dart';

import 'vrc_credential_subject.dart';

/// A parsed and verified VRC suitable for in-memory use and persistence.
class Vrc {
  const Vrc({
    required this.id,
    required this.vcBlob,
    required this.referenceId,
    required this.holderDid,
    required this.issuerDid,
    required this.issuedAt,
    this.verifiedAt,
    this.receivedAt,
    this.credentialFormat,
  });

  final String id;
  final String vcBlob;
  final String referenceId;
  final String holderDid;
  final String issuerDid;
  final DateTime issuedAt;
  final DateTime? verifiedAt;
  final DateTime? receivedAt;
  final String? credentialFormat;

  Vrc copyWith({
    String? id,
    String? vcBlob,
    String? referenceId,
    String? holderDid,
    String? issuerDid,
    DateTime? issuedAt,
    DateTime? verifiedAt,
    DateTime? receivedAt,
    String? credentialFormat,
  }) {
    return Vrc(
      id: id ?? this.id,
      vcBlob: vcBlob ?? this.vcBlob,
      referenceId: referenceId ?? this.referenceId,
      holderDid: holderDid ?? this.holderDid,
      issuerDid: issuerDid ?? this.issuerDid,
      issuedAt: issuedAt ?? this.issuedAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      receivedAt: receivedAt ?? this.receivedAt,
      credentialFormat: credentialFormat ?? this.credentialFormat,
    );
  }
}

extension ParsedVerifiableCredentialVrcExtension on ParsedVerifiableCredential {
  /// Maps a parsed VRC into the SDK's canonical representation.
  Vrc toVrc({
    required String referenceId,
    DateTime? verifiedAt,
    DateTime? receivedAt,
    String? credentialFormat,
  }) {
    final subjectJson = credentialSubject.firstOrNull as Map<String, dynamic>?;
    if (subjectJson == null) {
      throw StateError(
        'Cannot map VRC to domain model: credential has no subject',
      );
    }
    final subject = VrcCredentialSubject.fromJson(subjectJson);
    final credentialId = id;
    if (credentialId == null) {
      throw StateError('Cannot map VRC to domain model: credential has no id');
    }

    return Vrc(
      id: credentialId.toString(),
      vcBlob: serialized as String,
      referenceId: referenceId,
      holderDid: subject.to.did,
      issuerDid: subject.from.did,
      issuedAt: validFrom ?? DateTime.now().toUtc(),
      verifiedAt: verifiedAt,
      receivedAt: receivedAt,
      credentialFormat: credentialFormat,
    );
  }
}
