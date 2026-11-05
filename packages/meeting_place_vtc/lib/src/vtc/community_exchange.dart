import 'package:ssi/ssi.dart';

import '../meeting_place_vtc_sdk_exception.dart';
import '../proof/eddsa_jcs_2022.dart';
import '../sign_in/sign_in_agent.dart';
import '../transport/trust_task_http_transport.dart';
import '../trust_task/trust_task_document.dart';
import 'resolved_document.dart';
import 'vtc_resolver.dart';

/// A document of [type] from [persona] to [community], signed by the VTA.
///
/// The community verifies the proof against the persona's DID document.
Future<TrustTaskDocument> signedByPersona(
  SignInAgent agent,
  SignInPersona persona,
  VtcCommunityEndpoint community, {
  required String type,
  required Map<String, dynamic> payload,
}) async {
  final unsigned = TrustTaskDocument.create(
    type: type,
    issuer: persona.did,
    recipient: community.did,
    payload: payload,
  ).toJson();
  return TrustTaskDocument.fromJson(
    await signAsPersona(agent, persona, unsigned),
  );
}

/// Sends [request] to [community] over [transport] and returns the
/// community's answer, after checking that it answers [request] and is
/// signed by the community.
///
/// Throws [MeetingPlaceVtcSDKException] when the community refuses or
/// cannot be reached, or the answer fails a check.
Future<TrustTaskDocument> exchangeWithCommunity(
  TrustTaskHttpTransport transport,
  VtcCommunityEndpoint community,
  TrustTaskDocument request,
) async {
  final answer = await transport.send(community.trustTaskBase, request);
  if (answer.issuer != community.did || answer.threadId != request.id) {
    throw MeetingPlaceVtcSDKException.invalidDocument(
      'not an answer from the community to this request',
    );
  }
  await EddsaJcs2022.verify(
    answer.toJson(),
    purpose: ProofPurpose.authentication,
    resolver: ResolvedDocument(community.didDocument),
    expectedSigner: community.did,
  );
  return answer;
}
