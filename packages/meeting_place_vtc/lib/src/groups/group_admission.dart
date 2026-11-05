import 'package:ssi/ssi.dart';

import '../credentials/credential_fields.dart';
import '../meeting_place_vtc_sdk_exception.dart';
import '../proof/eddsa_jcs_2022.dart';
import '../status/status_list_client.dart';

/// Why a request to join a community group's chat was not let in.
enum GroupAdmissionRefusal {
  /// The presentation is missing, malformed, or its holder's proof does not
  /// verify.
  presentationInvalid,

  /// The presentation was made for another chat or another joiner.
  notForThisRequest,

  /// The membership credential is missing, malformed, not about the
  /// presentation's holder, or its issuer's proof does not verify.
  membershipInvalid,

  /// The membership credential was issued by another group.
  notThisGroup,

  /// The membership credential is not valid now.
  membershipExpired,

  /// The authority credential is missing, malformed, not the community's
  /// grant to this group to issue memberships, or its proof does not verify.
  authorityInvalid,

  /// The authority credential is not valid now.
  authorityExpired,

  /// The community revoked the authority credential.
  authorityRevoked,

  /// The authority credential's status could not be read.
  authorityStatusUnknown,
}

/// A request to join a group's chat that was not let in.
class GroupAdmissionException implements Exception {
  /// Creates a [GroupAdmissionException].
  const GroupAdmissionException(this.reason, {this.innerException});

  /// Why it was not let in.
  final GroupAdmissionRefusal reason;

  /// What failed underneath, if anything.
  final Object? innerException;

  @override
  String toString() => 'GroupAdmissionException(${reason.name})';
}

/// What a verified request to join a group's chat proves.
class GroupAdmission {
  /// Creates a [GroupAdmission].
  const GroupAdmission({
    required this.holderDid,
    required this.credentialId,
    required this.validUntil,
  });

  /// The member the group's credential is about, who presented it.
  final String holderDid;

  /// The credential's id: what `vtc/groups/members/list` shows a group's
  /// managers for each member, to confirm the membership live.
  final String credentialId;

  /// When the membership credential stops being valid.
  final DateTime validUntil;
}

/// Checks a request to join a community group's chat, offline but for DID
/// resolution and the community's status list.
///
/// A joiner presents the group's membership credential, made out to them by
/// the group's DID, in a presentation their VTA signs as them, bound to the
/// chat's DID and to the DID they join the chat as. The group's authority
/// credential, the community's grant to the group to issue memberships,
/// comes with it. The rules follow the DTG chain verifier
/// (`dtg-credentials` `authority::verify_chain`): the grant must be the
/// community's own, about the group, for `issue-membership`, carry a
/// `validUntil` and hold now.
///
/// The membership credential has no status list. Whether the joiner is
/// still a member is asked of the community separately, at approval.
///
/// Never logs a credential or a DID.
class GroupAdmissionVerifier {
  /// Creates a [GroupAdmissionVerifier] that resolves DIDs with
  /// [didResolver] and reads revocations with [statusListClient].
  GroupAdmissionVerifier({
    required DidResolver didResolver,
    required StatusListClient statusListClient,
    DateTime Function()? now,
  }) : _didResolver = didResolver,
       _statusListClient = statusListClient,
       _now = now ?? DateTime.now;

  /// The type of a group's membership credential.
  static const membershipType = 'MembershipCredential';

  /// The type of the community's grant to a group.
  static const authorityType = 'AuthorityCredential';

  /// The action a group needs to issue memberships.
  static const issueMembershipAction = 'issue-membership';

  final DidResolver _didResolver;
  final StatusListClient _statusListClient;
  final DateTime Function() _now;

  /// Verifies that [presentation] and [authority] admit [memberDid] to the
  /// chat of the group [groupDid], a group of the community [communityDid].
  ///
  /// Throws [GroupAdmissionException] when they do not.
  Future<GroupAdmission> verify({
    required Map<String, dynamic> presentation,
    required Map<String, dynamic> authority,
    required String groupDid,
    required String communityDid,
    required String memberDid,
  }) async {
    final now = _now();
    final holderDid = await _verifyPresentation(
      presentation,
      groupDid: groupDid,
      memberDid: memberDid,
    );
    final membership = await _verifyMembership(
      presentation,
      holderDid: holderDid,
      groupDid: groupDid,
      now: now,
    );
    await _verifyAuthority(
      authority,
      groupDid: groupDid,
      communityDid: communityDid,
      now: now,
    );
    return GroupAdmission(
      holderDid: holderDid,
      credentialId: membership.id,
      validUntil: membership.validUntil,
    );
  }

  /// Verifies the holder's proof on [presentation] and its binding to this
  /// chat and joiner, and returns the holder.
  Future<String> _verifyPresentation(
    Map<String, dynamic> presentation, {
    required String groupDid,
    required String memberDid,
  }) async {
    final holderDid = presentation['holder'];
    if (holderDid is! String ||
        !credentialTypes(presentation).contains('VerifiablePresentation')) {
      throw const GroupAdmissionException(
        GroupAdmissionRefusal.presentationInvalid,
      );
    }
    if (presentation['domain'] != groupDid ||
        presentation['nonce'] != memberDid) {
      throw const GroupAdmissionException(
        GroupAdmissionRefusal.notForThisRequest,
      );
    }
    await _verifyProof(
      presentation,
      purpose: ProofPurpose.authentication,
      signer: holderDid,
      refusal: GroupAdmissionRefusal.presentationInvalid,
    );
    return holderDid;
  }

  Future<({String id, DateTime validUntil})> _verifyMembership(
    Map<String, dynamic> presentation, {
    required String holderDid,
    required String groupDid,
    required DateTime now,
  }) async {
    final membership = switch (presentation['verifiableCredential']) {
      [final Map<String, dynamic> credential] => credential,
      final Map<String, dynamic> credential => credential,
      _ => throw const GroupAdmissionException(
        GroupAdmissionRefusal.membershipInvalid,
      ),
    };
    final id = membership['id'];
    final validUntil = DateTime.tryParse('${membership['validUntil']}');
    if (id is! String ||
        validUntil == null ||
        !credentialTypes(membership).contains(membershipType) ||
        !credentialSubjects(membership).contains(holderDid)) {
      throw const GroupAdmissionException(
        GroupAdmissionRefusal.membershipInvalid,
      );
    }
    if (credentialIssuer(membership) != groupDid) {
      throw const GroupAdmissionException(GroupAdmissionRefusal.notThisGroup);
    }
    if (!_holds(membership, validUntil: validUntil, now: now)) {
      throw const GroupAdmissionException(
        GroupAdmissionRefusal.membershipExpired,
      );
    }
    await _verifyProof(
      membership,
      purpose: ProofPurpose.assertionMethod,
      signer: groupDid,
      refusal: GroupAdmissionRefusal.membershipInvalid,
    );
    return (id: id, validUntil: validUntil);
  }

  Future<void> _verifyAuthority(
    Map<String, dynamic> authority, {
    required String groupDid,
    required String communityDid,
    required DateTime now,
  }) async {
    final grant = switch (authority['credentialSubject']) {
      {'id': final String subject, 'authority': final Map<String, dynamic> g}
          when subject == groupDid =>
        g,
      _ => null,
    };
    final actions = grant?['actions'];
    final validUntil = DateTime.tryParse('${authority['validUntil']}');
    if (grant == null ||
        validUntil == null ||
        !credentialTypes(authority).contains(authorityType) ||
        credentialIssuer(authority) != communityDid ||
        grant['scope'] != communityDid ||
        actions is! List ||
        !actions.contains(issueMembershipAction)) {
      throw const GroupAdmissionException(
        GroupAdmissionRefusal.authorityInvalid,
      );
    }
    if (!_holds(authority, validUntil: validUntil, now: now)) {
      throw const GroupAdmissionException(
        GroupAdmissionRefusal.authorityExpired,
      );
    }
    await _verifyProof(
      authority,
      purpose: ProofPurpose.assertionMethod,
      signer: communityDid,
      refusal: GroupAdmissionRefusal.authorityInvalid,
    );

    final CredentialStatusCheck status;
    try {
      status = await _statusListClient.check(authority);
    } on MeetingPlaceVtcSDKException catch (error) {
      throw GroupAdmissionException(
        GroupAdmissionRefusal.authorityStatusUnknown,
        innerException: error,
      );
    }
    if (status.state == CredentialStatusState.revoked) {
      throw const GroupAdmissionException(
        GroupAdmissionRefusal.authorityRevoked,
      );
    }
  }

  Future<void> _verifyProof(
    Map<String, dynamic> document, {
    required ProofPurpose purpose,
    required String signer,
    required GroupAdmissionRefusal refusal,
  }) async {
    try {
      await EddsaJcs2022.verify(
        document,
        purpose: purpose,
        resolver: _didResolver,
        expectedSigner: signer,
      );
    } on MeetingPlaceVtcSDKException catch (error) {
      throw GroupAdmissionException(refusal, innerException: error);
    }
  }

  /// Whether [credential] is valid at [now]: from its `validFrom`, if any,
  /// until [validUntil].
  static bool _holds(
    Map<String, dynamic> credential, {
    required DateTime validUntil,
    required DateTime now,
  }) {
    final validFrom = DateTime.tryParse('${credential['validFrom']}');
    return (validFrom == null || !now.isBefore(validFrom)) &&
        now.isBefore(validUntil);
  }
}
