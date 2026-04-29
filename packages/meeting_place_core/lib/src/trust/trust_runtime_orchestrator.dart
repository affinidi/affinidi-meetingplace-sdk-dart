import '../entity/group.dart';
import '../entity/group_member.dart';

/// Trust context provisioned for a group, typically by a VTC/TR service.
class TrustGroupContext {
  const TrustGroupContext({
    required this.vtcId,
    required this.trustRegistryId,
    this.communityVtaDid,
  });

  final String vtcId;
  final String trustRegistryId;
  final String? communityVtaDid;

  Map<String, String> toJson() {
    return {
      'vtcId': vtcId,
      'trustRegistryId': trustRegistryId,
      if (communityVtaDid != null) 'communityVtaDid': communityVtaDid!,
    };
  }
}

/// Reference to a credential issued for a group member.
class IssuedMembershipCredential {
  const IssuedMembershipCredential({
    required this.credentialId,
    this.issuerDid,
    this.scope,
  });

  final String credentialId;
  final String? issuerDid;
  final String? scope;

  Map<String, String> toJson() {
    return {
      'credentialId': credentialId,
      if (issuerDid != null) 'issuerDid': issuerDid!,
      if (scope != null) 'scope': scope!,
    };
  }
}

/// Proof payload attached to trust-enforced actions.
class TrustPresentationProof {
  const TrustPresentationProof({
    required this.credentialProof,
    this.issuerDid,
    this.scope,
  });

  final String credentialProof;
  final String? issuerDid;
  final String? scope;
}

/// SDK-side integration point for VTC/TR/VTA orchestration.
///
/// This keeps trust lifecycle hooks close to MPX SDK runtime:
/// - group creation -> provision VTC/TR context
/// - membership approval -> issue VC reference for member
/// - sensitive action send -> provide proof to control-plane trust check
abstract interface class TrustRuntimeOrchestrator {
  Future<TrustGroupContext?> onGroupCreated(Group group);

  Future<IssuedMembershipCredential?> onMembershipApproved({
    required Group group,
    required GroupMember member,
  });

  Future<TrustPresentationProof?> buildProofForAction({
    required Group group,
    required String actorDid,
    required String action,
  });
}

class NoopTrustRuntimeOrchestrator implements TrustRuntimeOrchestrator {
  const NoopTrustRuntimeOrchestrator();

  @override
  Future<TrustGroupContext?> onGroupCreated(Group group) async => null;

  @override
  Future<IssuedMembershipCredential?> onMembershipApproved({
    required Group group,
    required GroupMember member,
  }) async => null;

  @override
  Future<TrustPresentationProof?> buildProofForAction({
    required Group group,
    required String actorDid,
    required String action,
  }) async => null;
}

