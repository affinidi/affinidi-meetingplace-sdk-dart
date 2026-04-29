import 'trust_action.dart';

class TrustAuthorizationRequest {
  const TrustAuthorizationRequest({
    required this.action,
    required this.groupId,
    this.actorDid,
    this.subjectDid,
    this.credentialProof,
    this.scope,
    this.issuerDid,
    this.metadata,
  });

  final TrustAction action;
  final String groupId;
  final String? actorDid;
  final String? subjectDid;
  final String? credentialProof;
  final String? scope;
  final String? issuerDid;
  final Map<String, Object?>? metadata;

  Map<String, Object?> toJson() {
    return {
      'action': action.name,
      'groupId': groupId,
      if (actorDid != null) 'actorDid': actorDid,
      if (subjectDid != null) 'subjectDid': subjectDid,
      if (credentialProof != null) 'credentialProof': credentialProof,
      if (scope != null) 'scope': scope,
      if (issuerDid != null) 'issuerDid': issuerDid,
      if (metadata != null) 'metadata': metadata,
    };
  }
}
