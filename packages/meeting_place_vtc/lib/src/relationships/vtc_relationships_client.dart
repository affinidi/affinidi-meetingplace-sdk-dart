import 'package:ssi/ssi.dart';

import '../meeting_place_vtc_sdk_exception.dart';
import '../sign_in/sign_in_agent.dart';
import '../transport/trust_task_http_transport.dart';
import '../vta/vta_models.dart';
import '../vtc/community_exchange.dart';
import '../vtc/vtc_resolver.dart';
import 'published_relationship.dart';
import 'relationship_credential.dart';

/// Trust Task types of a community's trust graph, and the refusals callers
/// act on.
abstract final class RelationshipTask {
  static const _base = 'https://trusttasks.org/spec/vtc/relationships';

  /// Stores a member's relationship credential.
  static const publish = '$_base/publish/0.2';

  /// Lists the edges a member is a party to.
  static const list = '$_base/list/0.3';

  /// Withdraws an edge.
  static const revoke = '$_base/revoke/0.2';

  /// The credential is malformed or its proof does not verify.
  static const vrcInvalid = 'vtc/relationships/publish:vrcInvalid';

  /// The member vouched for is no current member.
  static const subjectNotMember = 'vtc/relationships/publish:subjectNotMember';

  /// The edge to withdraw is gone, or is not the caller's.
  static const revokeNotFound = 'vtc/relationships/revoke:notFound';

  /// The DID to list is no member of the community.
  static const listNotFound = 'vtc/relationships/list:notFound';
}

/// Publishes, lists and withdraws a member's vouches in a community's trust
/// graph, each request signed as the member's persona by their VTA.
///
/// A vouch is a relationship credential from the persona about another
/// member's persona: one direction of an edge, which the other member
/// completes by vouching back. Never logs a DID or a credential.
class VtcRelationshipsClient {
  /// Creates a [VtcRelationshipsClient].
  VtcRelationshipsClient({
    DidResolver? didResolver,
    TrustTaskHttpTransport? transport,
  }) : _transport = transport ?? TrustTaskHttpTransport(),
       _vtcResolver = VtcResolver(didResolver: didResolver);

  /// Most pages read for one list, so a community answering a cursor
  /// forever cannot keep the phone asking.
  static const maxPages = 50;

  /// Most edges asked for per page, the most the community answers.
  static const pageSize = 200;

  final TrustTaskHttpTransport _transport;
  final VtcResolver _vtcResolver;

  /// Has the VTA sign, as [persona], a vouch for the member [subjectDid] of
  /// the community [communityDid], and has the community store it.
  ///
  /// [signer] is the persona's vault entry for this community. Publishing
  /// the same credential again returns the same edge; a new credential
  /// about the same member replaces the earlier one, so callers check for
  /// an edge first. Throws [ArgumentError] when [subjectDid] is the
  /// persona's own, and [MeetingPlaceVtcSDKException] when the VTA or the
  /// community refuses, such as with [RelationshipTask.subjectNotMember],
  /// or cannot be reached.
  Future<PublishedRelationship> publish(
    String communityDid, {
    required PersonaSigningAgent agent,
    required VtaPersona persona,
    required SignInPersona signer,
    required String subjectDid,
  }) async {
    if (subjectDid == persona.did) {
      throw ArgumentError.value(subjectDid, 'subjectDid', 'is the persona');
    }
    final community = await _vtcResolver.resolveCommunity(communityDid);
    final vrc = await agent.signDocument(
      keyId: persona.signingKeyId,
      document: relationshipCredential(
        issuerDid: persona.did,
        subjectDid: subjectDid,
      ),
      purpose: ProofPurpose.assertionMethod.value,
    );
    final request = await signedByPersona(
      agent,
      signer,
      community,
      type: RelationshipTask.publish,
      payload: {'vrc': vrc},
    );
    final answer = await exchangeWithCommunity(_transport, community, request);
    final edge = PublishedRelationship.read(answer.payload);
    if (edge.issuerDid != persona.did || edge.subjectDid != subjectDid) {
      throw MeetingPlaceVtcSDKException.invalidDocument(
        'the community stored another edge',
      );
    }
    return edge;
  }

  /// Every edge of the community [communityDid] that [did] is a party to,
  /// either way round, asked as [persona].
  ///
  /// Throws [MeetingPlaceVtcSDKException] when the VTA or the community
  /// refuses, such as with [RelationshipTask.listNotFound] when [did] is no
  /// member, or cannot be reached, or the answer cannot be read.
  Future<List<PublishedRelationship>> list(
    String communityDid, {
    required SignInAgent agent,
    required SignInPersona persona,
    required String did,
  }) async {
    final community = await _vtcResolver.resolveCommunity(communityDid);
    final edges = <PublishedRelationship>[];
    String? cursor;
    for (var page = 0; page < maxPages; page++) {
      final request = await signedByPersona(
        agent,
        persona,
        community,
        type: RelationshipTask.list,
        payload: {'did': did, 'limit': pageSize, 'cursor': ?cursor},
      );
      final answer = (await exchangeWithCommunity(
        _transport,
        community,
        request,
      )).payload;
      final items = answer['items'];
      if (items is! List) {
        throw MeetingPlaceVtcSDKException.invalidDocument('no items');
      }
      edges.addAll([
        for (final item in items.whereType<Map<String, dynamic>>())
          PublishedRelationship.read(item),
      ]);
      cursor = answer['nextCursor'] is String
          ? answer['nextCursor'] as String
          : null;
      if (cursor == null) return edges;
    }
    throw MeetingPlaceVtcSDKException.invalidDocument('too many pages');
  }

  /// Withdraws the edge [id] of the community [communityDid], which
  /// [persona] issued.
  ///
  /// An edge that is gone already counts as withdrawn: the community
  /// answers an edge that is not the caller's the same way, so this never
  /// tells the two apart. Throws [MeetingPlaceVtcSDKException] on any other
  /// refusal, or when the VTA or the community cannot be reached.
  Future<void> revoke(
    String communityDid, {
    required SignInAgent agent,
    required SignInPersona persona,
    required String id,
  }) async {
    final community = await _vtcResolver.resolveCommunity(communityDid);
    final request = await signedByPersona(
      agent,
      persona,
      community,
      type: RelationshipTask.revoke,
      payload: {'id': id},
    );
    try {
      await exchangeWithCommunity(_transport, community, request);
    } on MeetingPlaceVtcSDKException catch (error) {
      if (error.refusalCode != RelationshipTask.revokeNotFound) rethrow;
    }
  }
}
