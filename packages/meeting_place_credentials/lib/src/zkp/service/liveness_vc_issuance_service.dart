import 'package:ssi/ssi.dart';

import '../builder/liveness_vc_builder.dart';
import '../model/liveness_evidence.dart';

/// Issues signed W3C liveness credentials from normalized provider evidence.
class LivenessVcIssuanceService {
  /// Creates a stateless liveness credential issuance service.
  const LivenessVcIssuanceService();

  /// Issues a signed liveness credential for the given holder.
  Future<VcDataModelV2> issue({
    required String issuerDid,
    required String holderDid,
    required DidManager issuerDidManager,
    required LivenessEvidence evidence,
    Duration validFor = const Duration(days: 5),
  }) {
    return LivenessVcBuilder.build(
      issuerDid: issuerDid,
      holderDid: holderDid,
      evidence: evidence,
      issuerDidManager: issuerDidManager,
      validFor: validFor,
    );
  }
}
