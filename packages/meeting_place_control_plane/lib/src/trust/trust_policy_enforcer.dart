import 'trust_authorization_request.dart';

abstract interface class TrustPolicyEnforcer {
  Future<void> enforceOrThrow(TrustAuthorizationRequest request);
}

class NoopTrustPolicyEnforcer implements TrustPolicyEnforcer {
  const NoopTrustPolicyEnforcer();

  @override
  Future<void> enforceOrThrow(TrustAuthorizationRequest request) async {}
}
