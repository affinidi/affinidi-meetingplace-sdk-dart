import 'package:ssi/ssi.dart';

import '../community/community_profile.dart';
import '../credentials/credential_fields.dart';
import '../meeting_place_vtc_sdk_exception.dart';
import '../proof/eddsa_jcs_2022.dart';
import '../proof/trust_task_signer.dart';
import '../sign_in/sign_in_agent.dart';
import '../transport/trust_task_http_transport.dart';
import '../trust_task/trust_task_document.dart';
import '../trust_task/trust_task_receipt.dart';
import '../vta/vta_models.dart';
import '../vtc/resolved_document.dart';
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
  /// naming it by its digest, with an empty presentation and the profile
  /// details in [attributes]. [registryConsent] is consent to publication in
  /// the community's trust registry. When the persona already has a request
  /// open, returns that request as [JoinPending].
  ///
  /// Throws [StateError] when the manifest has no criterion this wallet can
  /// apply under, or [criterion] is not one of [manifest]'s open criteria,
  /// and [MeetingPlaceVtcSDKException] when the VTA or the community
  /// refuses, cannot be reached, or answers with something else.
  Future<JoinVerdict> apply(
    JoinManifest manifest, {
    required SignInAgent agent,
    required SignInPersona persona,
    JoinCriterion? criterion,
    List<JoinAttribute> attributes = const [],
    bool registryConsent = false,
  }) async {
    final chosen = criterion ?? manifest.openCriterion;
    if (chosen == null) {
      throw StateError('the community has no criterion this wallet meets');
    }
    // Only a way in the community offers and this wallet can meet.
    if (!manifest.openCriteria.any(
      (open) =>
          open.id == chosen.id &&
          open.requirementsDigest == chosen.requirementsDigest,
    )) {
      throw StateError('not an open criterion of the community');
    }
    final community = manifest.community;
    final request = await _signedByPersona(
      agent,
      persona,
      community,
      type: JoinTask.submit,
      payload: {
        'vp': {
          '@context': ['https://www.w3.org/ns/credentials/v2'],
          'type': ['VerifiablePresentation'],
          'holder': persona.did,
          'verifiableCredential': <Object>[],
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
      receipt: TrustTaskReceipt.exchange(request, answer),
    );
    if (verdict is JoinAdmitted) {
      _checkCards(verdict, community: community.did, persona: persona.did);
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
      receipt: TrustTaskReceipt.exchange(request, answer),
    );
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
    final payload = await _ask(community, request);
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
    );
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
  ///
  /// The community verifies the proof against the persona's DID document.
  Future<TrustTaskDocument> _signedByPersona(
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
  ) async {
    final answer = await _transport.send(community.trustTaskBase, request);
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

  /// Refuses cards the community did not issue to [persona]: a membership
  /// card must be the community's `MembershipCredential` about the persona,
  /// a role card the community's `AuthorityCredential`. Their proofs are the
  /// VTA's to verify when it stores them.
  static void _checkCards(
    JoinAdmitted admitted, {
    required String community,
    required String persona,
  }) {
    final membership = admitted.membershipCard;
    if (membership != null &&
        (!credentialTypes(membership).contains('MembershipCredential') ||
            credentialIssuer(membership) != community ||
            !credentialSubjects(membership).contains(persona))) {
      throw MeetingPlaceVtcSDKException.invalidDocument(
        'a membership card not issued by the community to this persona',
      );
    }
    final role = admitted.roleCard;
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
    required TrustTaskReceipt receipt,
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
      'refer' => JoinPending(requestId: requestId, receipt: receipt),
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
      asksForCredentials: criterion['presentationDefinition'] != null,
      asksForVetting: criterion['vetting'] != null,
    );
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
