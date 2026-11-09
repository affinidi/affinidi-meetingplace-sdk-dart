import 'package:ssi/ssi.dart';

import '../community/community_profile.dart';
import '../credentials/credential_fields.dart';
import '../meeting_place_vtc_sdk_exception.dart';
import '../proof/trust_task_signer.dart';
import '../sign_in/sign_in_agent.dart';
import '../transport/trust_task_http_transport.dart';
import '../trust_task/trust_task_document.dart';
import '../trust_task/trust_task_exchange.dart';
import '../vetting/listed_vetter.dart';
import '../vetting/vetter_profile.dart';
import '../vetting/vetting_requirements.dart';
import '../vetting/vetting_statement.dart';
import '../vta/vta_models.dart';
import '../vtc/community_exchange.dart';
import '../vtc/service_endpoints.dart';
import '../vtc/vtc_resolver.dart';
import 'join_models.dart';
import 'membership_confirmation.dart';

/// The `vtc/join-requests` Trust Task types this client sends.
abstract final class JoinTask {
  static const _base = 'https://trusttasks.org/spec/vtc/join-requests';

  /// Reads what the community asks of applicants.
  static const manifest = '$_base/manifest/0.4';

  /// Applies to join, signed by the applicant's persona.
  static const submit = '$_base/submit/0.3';

  /// Asks where the applicant's request stands.
  static const status = '$_base/status/0.1';

  /// Withdraws the applicant's open request. A draft upstream: the version
  /// may change.
  static const withdraw = '$_base/withdraw/0.1';
}

/// The `vtc/vetting` Trust Task types this client sends.
abstract final class VettingCommunityTask {
  /// Lists the vetters the community lets applicants find.
  static const vettersList =
      'https://trusttasks.org/spec/vtc/vetting/vetters/list/0.1';

  /// Publishes, replaces or unlists the vetter's own profile.
  static const vettersProfile =
      'https://trusttasks.org/spec/vtc/vetting/vetters/profile/0.1';

  /// The community's refusal of a profile from a sender holding no live
  /// vetter grant there.
  static const profileNotEligible = 'vtc/vetting/vetters/profile:notEligible';
}

/// The `vtc/members` Trust Task types this client sends.
abstract final class MemberTask {
  /// Hands the community the member's own membership credential.
  static const vmc = 'https://trusttasks.org/spec/vtc/members/vmc/0.1';

  /// Ends the member's own membership.
  static const selfRemove =
      'https://trusttasks.org/spec/vtc/members/self-remove/0.1';

  /// Changes the member's own card in the member directory.
  static const directoryCardUpdate =
      'https://trusttasks.org/spec/vtc/directory/card/update/0.1';

  /// Re-issues the member's own membership and role cards.
  static const renew = 'https://trusttasks.org/spec/vtc/members/renew/0.1';

  /// Refusal code of a renewal by someone who is not a member.
  static const notMember = 'vtc/members/renew:notMember';

  /// Reads the membership pair the community holds for a member, which
  /// only administrators who manage members may.
  static const credentials =
      'https://trusttasks.org/spec/vtc/members/credentials/0.1';

  /// Refusal code of [credentials] for a DID that is no member.
  static const credentialsNotFound = 'vtc/members/credentials:notFound';
}

/// Refusals of a confirmation naming a request the community no longer
/// matches to this member; the confirmation stands without it.
const _requestMismatches = {
  'vtc/members/vmc:requestNotFound',
  'vtc/members/vmc:requestNotApproved',
  'vtc/members/vmc:requestApplicantMismatch',
};

/// Refusal code of a submit while the applicant already has a request open.
const _requestAlreadyOpen = 'vtc/join-requests/submit:requestAlreadyOpen';

/// Applies to join a Verifiable Trust Community as a persona the member's
/// VTA holds.
///
/// The community is reached at the Trust Task endpoint of its resolved DID
/// document, never at an address from a QR code. Each answer must be signed
/// by the community's key from that same document and must answer the
/// request it was sent for. Nothing is logged.
class VtcJoinClient {
  /// Creates a [VtcJoinClient].
  VtcJoinClient({DidResolver? didResolver, TrustTaskHttpTransport? transport})
    : _transport = transport ?? TrustTaskHttpTransport(),
      _vtcResolver = VtcResolver(didResolver: didResolver);

  final TrustTaskHttpTransport _transport;
  final VtcResolver _vtcResolver;

  /// Reads the join manifest of the community [communityDid], such as the
  /// bare DID its QR code shows.
  ///
  /// Asks as a throwaway key: the manifest is public and the applicant has
  /// no persona yet. Throws [MeetingPlaceVtcSDKException] when the community
  /// cannot be resolved or reached, refuses, or answers with something else.
  Future<JoinManifest> readManifest(String communityDid) async {
    final community = await _vtcResolver.resolveCommunity(communityDid);
    final requester = Ed25519DidKeySigner.generate();
    final request = await TrustTaskDocument.create(
      type: JoinTask.manifest,
      issuer: requester.did,
      recipient: community.did,
      payload: const {},
    ).sign(requester, purpose: ProofPurpose.authentication);

    final payload = await _ask(community, request);
    if (payload['communityDid'] != community.did) {
      throw MeetingPlaceVtcSDKException.invalidDocument(
        'manifest of another community',
      );
    }
    final branding = payload['branding'];
    final name = branding is Map ? branding['displayName'] : null;
    final logoUrl = branding is Map ? branding['logoUrl'] : null;
    return JoinManifest(
      community: community,
      criteria: [
        for (final criterion in _maps(payload['criteria']))
          ?_criterion(criterion),
      ],
      name: name is String && name.trim().isNotEmpty ? name.trim() : null,
      logoUrl: httpsUrl(logoUrl),
      requestedAttributes: [
        for (final attribute in _maps(payload['requestedAttributes']))
          if (attribute['type'] case final String type)
            JoinAttributeRequest(
              type: type,
              // Absent means required.
              required: attribute['required'] != false,
              purpose: attribute['purpose'] is String
                  ? attribute['purpose'] as String
                  : null,
            ),
      ],
      listsNewMembers: _listsNewMembers(payload['directoryDisclosure']),
      directoryDisclosure: _directoryDisclosure(payload['directoryDisclosure']),
      document: Map.unmodifiable(payload),
    );
  }

  /// Reads what the community [communityDid] publishes about itself to
  /// anyone (`GET <base>/community/public-profile`), at the Trust Task base
  /// of its resolved DID document.
  ///
  /// The profile is not signed, so it describes the community and decides
  /// nothing; links in it are kept only when `https`. Throws
  /// [MeetingPlaceVtcSDKException] when the community cannot be resolved or
  /// reached, or answers with another community's profile.
  Future<CommunityProfile> readProfile(String communityDid) async {
    final community = await _vtcResolver.resolveCommunity(communityDid);
    final base = community.trustTaskBase;
    final path = base.path.replaceAll(RegExp(r'/+$'), '');
    final profile = await _transport.fetchJson(
      base.replace(path: '$path/community/public-profile'),
    );
    if (profile['communityDid'] != community.did) {
      throw MeetingPlaceVtcSDKException.invalidDocument(
        'profile of another community',
      );
    }
    String? text(Object? value) =>
        value is String && value.trim().isNotEmpty ? value.trim() : null;
    final personhood = profile['personhood'];
    return CommunityProfile(
      communityDid: community.did,
      name: text(profile['name']),
      description: text(profile['description']),
      logoUrl: httpsUrl(profile['logoUrl']),
      website: httpsUrl(profile['publicUrl']),
      contactEmail: text(profile['contactEmail']),
      personhood: personhood is Map
          ? CommunityPersonhood(
              realHuman: personhood['realHuman'] == true,
              singleMembership: personhood['singleMembership'] == true,
              governanceFrameworkUrl: httpsUrl(
                personhood['governanceFrameworkUrl'],
              ),
            )
          : const CommunityPersonhood(),
    );
  }

  /// Applies to join [manifest]'s community as [persona], whose document
  /// [agent] (the member's VTA) signs.
  ///
  /// Applies under [criterion], or else [JoinManifest.openCriterion],
  /// naming it by its digest, with the profile details in [attributes].
  /// [registryConsent] is consent to publication in the community's trust
  /// registry. When the persona already has a request open, returns that
  /// request as [JoinPending].
  ///
  /// A criterion that asks for credentials alone is met with
  /// [presentation]: a W3C presentation by [persona] of the credentials it
  /// asks for, such as the VTA's `vault/credentials/present` makes for the
  /// community. A criterion that asks for vetting alone is met with
  /// [vettingStatements], the vetters' statements about [persona], which
  /// go in a presentation by [persona]. An open criterion is met with an
  /// empty one.
  ///
  /// Throws [StateError] when the manifest has no criterion this wallet can
  /// apply under, [criterion] is not one of [manifest]'s criteria this
  /// wallet can meet, or [presentation] or [vettingStatements] is missing,
  /// not [persona]'s or not asked for; and [MeetingPlaceVtcSDKException]
  /// when the VTA or the community refuses, cannot be reached, or answers
  /// with something else.
  Future<JoinVerdict> apply(
    JoinManifest manifest, {
    required SignInAgent agent,
    required SignInPersona persona,
    JoinCriterion? criterion,
    Map<String, dynamic>? presentation,
    List<VettingStatement> vettingStatements = const [],
    List<JoinAttribute> attributes = const [],
    bool registryConsent = false,
  }) async {
    final chosen = criterion ?? manifest.openCriterion;
    if (chosen == null) {
      throw StateError('the community has no criterion this wallet meets');
    }
    // Only a way in the community offers and this wallet can meet.
    if (!manifest.criteria.any(
      (offered) =>
          offered.id == chosen.id &&
          offered.requirementsDigest == chosen.requirementsDigest &&
          (offered.isOpen ||
              offered.asksOnlyForCredentials ||
              offered.asksOnlyForVetting),
    )) {
      throw StateError('not a criterion of the community this wallet meets');
    }
    if (chosen.asksForCredentials != (presentation != null)) {
      throw StateError(
        chosen.asksForCredentials
            ? 'the criterion asks for credentials'
            : 'the criterion asks for no credentials',
      );
    }
    if (presentation != null && presentation['holder'] != persona.did) {
      throw StateError('a presentation by another holder');
    }
    if (chosen.asksForVetting != vettingStatements.isNotEmpty) {
      throw StateError(
        chosen.asksForVetting
            ? 'the criterion asks for vetting'
            : 'the criterion asks for no vetting',
      );
    }
    if (vettingStatements.any((s) => s.applicantDid != persona.did)) {
      throw StateError('a statement about another applicant');
    }
    final community = manifest.community;
    final request = await _signedByPersona(
      agent,
      persona,
      community,
      type: JoinTask.submit,
      payload: {
        'vp':
            presentation ??
            {
              '@context': ['https://www.w3.org/ns/credentials/v2'],
              'type': ['VerifiablePresentation'],
              'holder': persona.did,
              'verifiableCredential': [
                for (final statement in vettingStatements) statement.credential,
              ],
            },
        'criterion': chosen.requirementsDigest,
        if (attributes.isNotEmpty)
          'attributes': [
            for (final attribute in attributes) attribute.toJson(),
          ],
        'registryConsent': registryConsent,
      },
    );

    final TrustTaskDocument answer;
    try {
      answer = await _exchange(community, request);
    } on MeetingPlaceVtcSDKException catch (error) {
      final openRequestId = error.errorPayload?['details'] is Map
          ? (error.errorPayload!['details'] as Map)['requestId']
          : null;
      if (error.refusalCode == _requestAlreadyOpen && openRequestId is String) {
        return JoinPending(requestId: openRequestId);
      }
      rethrow;
    }
    final verdict = _verdict(
      answer.payload,
      exchange: TrustTaskExchange(request: request, answer: answer),
    );
    if (verdict is JoinAdmitted) {
      _checkCards(
        membership: verdict.membershipCard,
        role: verdict.roleCard,
        community: community.did,
        persona: persona.did,
      );
    }
    return verdict;
  }

  /// Asks the community [communityDid] where [persona]'s request
  /// [requestId] stands. With [resendCredentials], asks it to deliver an
  /// approved request's cards again.
  ///
  /// Throws [MeetingPlaceVtcSDKException] when the VTA or the community
  /// refuses, cannot be reached, or answers with something else.
  Future<JoinStatus> status(
    String communityDid, {
    required String requestId,
    required SignInAgent agent,
    required SignInPersona persona,
    bool resendCredentials = false,
  }) async {
    final community = await _vtcResolver.resolveCommunity(communityDid);
    final request = await _signedByPersona(
      agent,
      persona,
      community,
      type: JoinTask.status,
      payload: {
        'requestId': requestId,
        if (resendCredentials) 'resendCredentials': true,
      },
    );
    final answer = await _exchange(community, request);
    final payload = answer.payload;
    final status = JoinRequestStatus.values.asNameMap()[payload['status']];
    if (payload['requestId'] != requestId || status == null) {
      throw MeetingPlaceVtcSDKException.invalidDocument('no request status');
    }
    return JoinStatus(
      status: status,
      reason: payload['reason'] is String ? payload['reason'] as String : null,
      credentialsDelivered: payload['credentialsDelivered'] is bool
          ? payload['credentialsDelivered'] as bool
          : null,
      exchange: TrustTaskExchange(request: request, answer: answer),
    );
  }

  /// Withdraws [persona]'s open request [requestId] to the community
  /// [communityDid], which then counts as `withdrawn`; the persona may apply
  /// again. Returns the signed request and the community's verified answer.
  ///
  /// Throws [MeetingPlaceVtcSDKException] when the VTA or the community
  /// refuses, cannot be reached, or answers with something else: refused
  /// with a code ending in `:notFound` when no such request of [persona] is
  /// open, and in `:alreadyDecided` when the community decided on it.
  Future<TrustTaskExchange> withdraw(
    String communityDid, {
    required String requestId,
    required SignInAgent agent,
    required SignInPersona persona,
  }) async {
    final community = await _vtcResolver.resolveCommunity(communityDid);
    final request = await _signedByPersona(
      agent,
      persona,
      community,
      type: JoinTask.withdraw,
      payload: {'requestId': requestId},
    );
    final answer = await _exchange(community, request);
    final payload = answer.payload;
    if (payload['requestId'] != requestId || payload['status'] != 'withdrawn') {
      throw MeetingPlaceVtcSDKException.invalidDocument('not withdrawn');
    }
    return TrustTaskExchange(request: request, answer: answer);
  }

  /// Takes [persona]'s card in the community [communityDid] out of the
  /// member directory: not listed, not searchable, not published outside
  /// the community (`vtc/directory/card/update/0.1`).
  ///
  /// A community lists new members by its own default; this is how a member
  /// who did not opt in is withdrawn. Throws [MeetingPlaceVtcSDKException]
  /// when the VTA or the community refuses or cannot be reached.
  Future<void> hideDirectoryCard(
    String communityDid, {
    required SignInAgent agent,
    required SignInPersona persona,
  }) async {
    final community = await _vtcResolver.resolveCommunity(communityDid);
    final request = await _signedByPersona(
      agent,
      persona,
      community,
      type: MemberTask.directoryCardUpdate,
      payload: const {
        'discoverability': {
          'listing': 'hidden',
          'search': 'off',
          'external': false,
        },
      },
    );
    await _ask(community, request);
  }

  /// Leaves the community [communityDid] as [persona]
  /// (`vtc/members/self-remove/0.1`). The community keeps what its policy
  /// or the member's stored preference says, and revokes the membership.
  ///
  /// Throws [MeetingPlaceVtcSDKException] when the VTA or the community
  /// refuses or cannot be reached: refused with a code ending in
  /// `:notMember` when [persona] is no member, and with HTTP status 409 when
  /// [persona] is the community's last administrator.
  Future<LeaveReceipt> leave(
    String communityDid, {
    required SignInAgent agent,
    required SignInPersona persona,
  }) async {
    final community = await _vtcResolver.resolveCommunity(communityDid);
    final request = await _signedByPersona(
      agent,
      persona,
      community,
      type: MemberTask.selfRemove,
      payload: const {},
    );
    final answer = await _exchange(community, request);
    final payload = answer.payload;
    final disposition = payload['disposition'];
    final removed = payload['removed'];
    if (payload['did'] != persona.did ||
        disposition is! String ||
        removed is! bool) {
      throw MeetingPlaceVtcSDKException.invalidDocument('no leave receipt');
    }
    return LeaveReceipt(
      did: persona.did,
      disposition: disposition,
      removed: removed,
      exchange: TrustTaskExchange(request: request, answer: answer),
    );
  }

  /// Asks the community [communityDid] for [persona]'s current cards
  /// (`vtc/members/renew/0.1`), which also tells whether the persona is
  /// still a member.
  ///
  /// The community re-issues both cards on every call, at the role the
  /// member holds now: this is how a member learns of a role change whose
  /// pushed card never arrived. Returns `null` when the community says
  /// [persona] is not a member.
  ///
  /// Throws [MeetingPlaceVtcSDKException] when the VTA or the community
  /// refuses otherwise, cannot be reached, or answers with something else.
  Future<MembershipCards?> renew(
    String communityDid, {
    required SignInAgent agent,
    required SignInPersona persona,
  }) async {
    final community = await _vtcResolver.resolveCommunity(communityDid);
    final request = await _signedByPersona(
      agent,
      persona,
      community,
      type: MemberTask.renew,
      payload: const {},
    );

    final Map<String, dynamic> payload;
    try {
      payload = await _ask(community, request);
    } on MeetingPlaceVtcSDKException catch (error) {
      if (error.refusalCode == MemberTask.notMember) return null;
      rethrow;
    }

    final membership = payload['vmc'];
    final role = payload['roleVac'];
    if (payload['did'] != persona.did ||
        membership is! Map<String, dynamic> ||
        role is! Map<String, dynamic>) {
      throw MeetingPlaceVtcSDKException.invalidDocument('no renewed cards');
    }
    _checkCards(
      membership: membership,
      role: role,
      community: community.did,
      persona: persona.did,
    );
    return MembershipCards(membership: membership, role: role);
  }

  /// The membership pair the community [communityDid] holds for the member
  /// [did], read as [persona], or null when [did] is no member.
  ///
  /// Only an administrator who manages members may read it: anyone else is
  /// refused `permissionDenied`. Throws [MeetingPlaceVtcSDKException] when
  /// the VTA or the community refuses, cannot be reached, or answers with
  /// something else.
  Future<MemberCredentials?> memberCredentials(
    String communityDid, {
    required SignInAgent agent,
    required SignInPersona persona,
    required String did,
  }) async {
    final community = await _vtcResolver.resolveCommunity(communityDid);
    final request = await _signedByPersona(
      agent,
      persona,
      community,
      type: MemberTask.credentials,
      payload: {'did': did},
    );
    final Map<String, dynamic> payload;
    try {
      payload = await _ask(community, request);
    } on MeetingPlaceVtcSDKException catch (error) {
      if (error.refusalCode == MemberTask.credentialsNotFound) return null;
      rethrow;
    }
    if (payload['did'] != did) {
      throw MeetingPlaceVtcSDKException.invalidDocument('another member');
    }
    Map<String, dynamic>? credential(String key) =>
        payload[key] is Map<String, dynamic>
        ? payload[key] as Map<String, dynamic>
        : null;
    return MemberCredentials(
      membershipCredential: credential('membershipCredential'),
      roleCredential: credential('roleCredential'),
      memberVmc: credential('memberVmc'),
      isMemberVmcBound: payload['memberVmcBound'] == true,
    );
  }

  /// The most pages of vetters [listVetters] reads.
  static const maxVetterPages = 10;

  /// The vetters the community [communityDid] lists, asked as [persona]: the
  /// community lists vetters only to callers it can identify. Reads up to
  /// [maxVetterPages] pages, in the community's order.
  ///
  /// Throws [MeetingPlaceVtcSDKException] when the community refuses,
  /// cannot be reached, or answers with something else.
  Future<List<ListedVetter>> listVetters(
    String communityDid, {
    required SignInAgent agent,
    required SignInPersona persona,
  }) async {
    final community = await _vtcResolver.resolveCommunity(communityDid);
    final vetters = <ListedVetter>[];
    String? cursor;
    for (var page = 0; page < maxVetterPages; page++) {
      final request = await _signedByPersona(
        agent,
        persona,
        community,
        type: VettingCommunityTask.vettersList,
        payload: {'limit': 100, 'cursor': ?cursor},
      );
      final payload = await _ask(community, request);
      final listed = payload['vetters'];
      if (listed is! List) {
        throw MeetingPlaceVtcSDKException.invalidDocument('no vetters');
      }
      vetters.addAll([for (final vetter in listed) ?ListedVetter.read(vetter)]);
      cursor = payload['nextCursor'] is String
          ? payload['nextCursor'] as String
          : null;
      if (cursor == null) break;
    }
    return vetters;
  }

  /// Publishes [profile] as [persona]'s vetter profile with the community
  /// [communityDid] (`vtc/vetting/vetters/profile/0.1`), replacing what it
  /// held.
  ///
  /// Throws [MeetingPlaceVtcSDKException] with an `invalidDocument` code
  /// for a profile [VetterProfile.check] refuses, before anything is sent;
  /// refused with [VettingCommunityTask.profileNotEligible] when [persona]
  /// holds no live vetter grant there; and when the VTA or the community
  /// cannot be reached or answers with something else.
  Future<PublishedVetterProfile> publishVetterProfile(
    String communityDid,
    VetterProfile profile, {
    required SignInAgent agent,
    required SignInPersona persona,
  }) async {
    final payload = profile.toJson();
    final community = await _vtcResolver.resolveCommunity(communityDid);
    final request = await _signedByPersona(
      agent,
      persona,
      community,
      type: VettingCommunityTask.vettersProfile,
      payload: payload,
    );
    final answer = await _ask(community, request);
    final listed = answer['listed'];
    final updatedAt = DateTime.tryParse('${answer['updatedAt']}');
    if (listed is! bool || updatedAt == null) {
      throw MeetingPlaceVtcSDKException.invalidDocument(
        'not a stored vetter profile',
      );
    }
    return PublishedVetterProfile(listed: listed, updatedAt: updatedAt);
  }

  /// Confirms [persona]'s membership back to the community [communityDid]:
  /// the VTA signs, as the persona, a membership credential bound to
  /// [communityCard], the card the community issued, and the community
  /// stores it (`vtc/members/vmc/0.1`). [requestId] names the admitted
  /// request, to mark it reciprocated.
  ///
  /// [signer] is the persona's vault entry for this community. Throws
  /// [MeetingPlaceVtcSDKException] when the VTA or the community refuses,
  /// cannot be reached, or does not confirm it stored the credential.
  Future<void> confirmMembership(
    String communityDid, {
    required PersonaSigningAgent agent,
    required VtaPersona persona,
    required SignInPersona signer,
    required Map<String, dynamic> communityCard,
    String? requestId,
  }) async {
    final community = await _vtcResolver.resolveCommunity(communityDid);
    final credential = await agent.signDocument(
      keyId: persona.signingKeyId,
      document: memberMembershipCredential(
        personaDid: persona.did,
        communityDid: community.did,
        communityCard: communityCard,
      ),
      purpose: ProofPurpose.assertionMethod.value,
    );

    Future<void> send(String? requestId) async {
      final request = await _signedByPersona(
        agent,
        signer,
        community,
        type: MemberTask.vmc,
        payload: {'vc': credential, 'requestId': ?requestId},
      );
      final payload = await _ask(community, request);
      if (payload['status'] != 'stored') {
        throw MeetingPlaceVtcSDKException.invalidDocument(
          'the community did not store the membership credential',
        );
      }
    }

    try {
      await send(requestId);
    } on MeetingPlaceVtcSDKException catch (error) {
      if (requestId == null ||
          !_requestMismatches.contains(error.refusalCode)) {
        rethrow;
      }
      await send(null);
    }
  }

  /// A document of [type] from [persona] to [community], signed by the VTA.
  Future<TrustTaskDocument> _signedByPersona(
    SignInAgent agent,
    SignInPersona persona,
    VtcCommunityEndpoint community, {
    required String type,
    required Map<String, dynamic> payload,
  }) => signedByPersona(
    agent,
    persona,
    community,
    type: type,
    payload: payload,
  );

  /// Sends [request] and returns the payload of the community's answer to
  /// it, after checking that answer.
  Future<Map<String, dynamic>> _ask(
    VtcCommunityEndpoint community,
    TrustTaskDocument request,
  ) async => (await _exchange(community, request)).payload;

  /// Sends [request] and returns the community's answer to it, after
  /// checking that it answers [request] and is signed by the community.
  Future<TrustTaskDocument> _exchange(
    VtcCommunityEndpoint community,
    TrustTaskDocument request,
  ) => exchangeWithCommunity(_transport, community, request);

  /// Refuses cards the community did not issue to [persona]: a membership
  /// card must be the community's `MembershipCredential` about the persona,
  /// a role card the community's `AuthorityCredential`. Their proofs are the
  /// VTA's to verify when it stores them.
  static void _checkCards({
    required Map<String, dynamic>? membership,
    required Map<String, dynamic>? role,
    required String community,
    required String persona,
  }) {
    if (membership != null &&
        (!credentialTypes(membership).contains('MembershipCredential') ||
            credentialIssuer(membership) != community ||
            !credentialSubjects(membership).contains(persona))) {
      throw MeetingPlaceVtcSDKException.invalidDocument(
        'a membership card not issued by the community to this persona',
      );
    }
    if (role != null &&
        (!credentialTypes(role).contains('AuthorityCredential') ||
            credentialIssuer(role) != community)) {
      throw MeetingPlaceVtcSDKException.invalidDocument(
        'a role card not issued by the community',
      );
    }
  }

  static JoinVerdict _verdict(
    Map<String, dynamic> payload, {
    required TrustTaskExchange exchange,
  }) {
    final requestId = payload['requestId'];
    final verdict = payload['verdict'];
    if (requestId is! String || verdict is! Map) {
      throw MeetingPlaceVtcSDKException.invalidDocument('no verdict');
    }
    final details = verdict['with'] is Map
        ? verdict['with'] as Map
        : const <String, dynamic>{};

    return switch (verdict['effect']) {
      'allow' => JoinAdmitted(
        requestId: requestId,
        membershipCard: details['vmc'] is Map<String, dynamic>
            ? details['vmc'] as Map<String, dynamic>
            : null,
        // `roleVec` is the name before role credentials became VACs.
        roleCard: switch (details['roleVac'] ?? details['roleVec']) {
          final Map<String, dynamic> card => card,
          _ => null,
        },
        role: details['role'] is String ? details['role'] as String : null,
      ),
      'refer' => JoinPending(requestId: requestId, exchange: exchange),
      'deny' => JoinDenied(
        requestId: requestId,
        reason: details['reason'] is String
            ? details['reason'] as String
            : null,
      ),
      'requestMore' => JoinNeedsMore(requestId: requestId),
      _ => throw MeetingPlaceVtcSDKException.invalidDocument('unknown verdict'),
    };
  }

  /// A criterion, or null for one this wallet cannot read: no id, an
  /// admission it does not know, or no digest to name it by.
  static JoinCriterion? _criterion(Map<String, dynamic> criterion) {
    final id = criterion['id'];
    final admission = JoinAdmission.values.asNameMap()[criterion['admission']];
    final digest = criterion['requirementsDigest'];
    if (id is! String || admission == null || digest is! String) return null;
    final description = criterion['description'];
    return JoinCriterion(
      id: id,
      admission: admission,
      requirementsDigest: digest,
      description: description is String ? description : null,
      invitationRequired: criterion['invitationRequired'] == true,
      credentials: _credentialRequest(criterion),
      asksForVetting: criterion['vetting'] != null,
      vetting: VettingRequirements.read(criterion['vetting']),
    );
  }

  /// What [criterion]'s `presentationDefinition` asks for, or null when it
  /// asks for no credentials. A query this wallet cannot read in full is
  /// kept without type alternatives, so the criterion stays one it cannot
  /// meet.
  static JoinCredentialRequest? _credentialRequest(
    Map<String, dynamic> criterion,
  ) {
    final query = criterion['presentationDefinition'];
    if (query == null) return null;
    final issuers =
        JoinCredentialIssuers.values
            .asNameMap()[criterion['credentialIssuers']] ??
        // Absent or unknown is read the restrictive way, as the community
        // reads it.
        JoinCredentialIssuers.community;
    if (query is! Map<String, dynamic>) {
      return JoinCredentialRequest(query: const {}, issuers: issuers);
    }
    return JoinCredentialRequest(
      query: Map.unmodifiable(query),
      issuers: issuers,
      typeAlternatives: _typeAlternatives(query) ?? const [],
    );
  }

  /// The type alternatives of each credential [query] asks for, or null
  /// when it asks for anything but W3C credentials selected by type: other
  /// formats, claims, credential sets or trusted authorities.
  static List<List<List<String>>>? _typeAlternatives(
    Map<String, dynamic> query,
  ) {
    final credentials = query['credentials'];
    if (credentials is! List ||
        credentials.isEmpty ||
        query['credential_sets'] != null) {
      return null;
    }
    final wanted = <List<List<String>>>[];
    for (final credential in credentials) {
      if (credential is! Map ||
          credential['format'] != 'ldp_vc' ||
          credential['claims'] != null ||
          credential['trusted_authorities'] != null) {
        return null;
      }
      final meta = credential['meta'];
      final alternatives = meta is Map ? meta['type_values'] : null;
      if (alternatives is! List || alternatives.isEmpty) return null;
      final read = <List<String>>[];
      for (final types in alternatives) {
        if (types is! List ||
            types.isEmpty ||
            types.any((type) => type is! String)) {
          return null;
        }
        read.add(List.unmodifiable(types.cast<String>()));
      }
      wanted.add(List.unmodifiable(read));
    }
    return List.unmodifiable(wanted);
  }

  /// Whether `directoryDisclosure.newCard.listing` lists new members: a
  /// `hidden` card is not, a `listed` or `findable` one is.
  static bool? _listsNewMembers(Object? disclosure) {
    final newCard = disclosure is Map ? disclosure['newCard'] : null;
    final listing = newCard is Map ? newCard['listing'] : null;
    return switch (listing) {
      'hidden' => false,
      'listed' || 'findable' => true,
      _ => null,
    };
  }

  /// The disclosure, or null when the community offers no directory or the
  /// statement lacks a member it requires.
  static DirectoryDisclosure? _directoryDisclosure(Object? disclosure) {
    if (disclosure is! Map) return null;
    final audiences = DirectoryAudience.values.asNameMap();
    final sources = DirectoryFieldSource.values.asNameMap();
    final membershipIdentifiers =
        audiences[disclosure['membershipIdentifiers']];
    final adminNotes = disclosure['adminNotes'];
    final externalCards = disclosure['externalCards'];
    if (membershipIdentifiers == null ||
        adminNotes is! bool ||
        externalCards is! bool) {
      return null;
    }
    return DirectoryDisclosure(
      fields: [
        for (final field in _maps(disclosure['fields']))
          if ((
                field['label'],
                sources[field['source']],
                audiences[field['ceiling']],
                audiences[field['defaultVisibility']],
              )
              case (
                final String label,
                final DirectoryFieldSource source,
                final DirectoryAudience ceiling,
                final DirectoryAudience defaultVisibility,
              ))
            DirectoryField(
              label: label,
              description: field['description'] is String
                  ? field['description'] as String
                  : null,
              source: source,
              ceiling: ceiling,
              defaultVisibility: defaultVisibility,
            ),
      ],
      membershipIdentifiers: membershipIdentifiers,
      adminNotes: adminNotes,
      externalCards: externalCards,
    );
  }

  static Iterable<Map<String, dynamic>> _maps(Object? list) => switch (list) {
    final List<dynamic> entries => entries.whereType<Map<String, dynamic>>(),
    _ => const [],
  };
}
