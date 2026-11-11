import '../credentials/credential_fields.dart';
import '../meeting_place_vtc_sdk_exception.dart';
import '../status/status_list_client.dart';
import '../vetting/vetter_role_card.dart';
import '../vta/vta_client.dart';
import '../vta/vta_models.dart';

/// Vault purpose of membership credentials.
const _membershipPurpose = 'membership';

/// VC type of the role card a community issues its members. The vault files
/// it under no purpose, so it is found by type.
const _roleCardType = 'AuthorityCredential';

/// Prefix of the action by which a role card grants a role, as in
/// `role:member`.
const _roleActionPrefix = 'role:';

/// A step of finding a membership card on the member's VTA, in order.
enum MembershipCardStep {
  /// Asking the VTA which cards it keeps from the community.
  finding,

  /// Fetching the card the VTA found.
  reading,
}

/// A community the member belongs to, and the persona they are known by.
class CommunityMembership {
  /// Creates a [CommunityMembership].
  const CommunityMembership({
    required this.communityDid,
    required this.persona,
    this.name,
  });

  /// The community's DID.
  final String communityDid;

  /// The member's persona in the community.
  final VtaPersona persona;

  /// The community's name, if the membership card carries one.
  final String? name;
}

/// Finds the member's persona in a community from the membership cards
/// another device, such as Keyring, backed up to the member's VTA.
///
/// The result only chooses which persona to sign in as; the community still
/// decides whether that persona is a member.
class CommunityImport {
  /// Creates a [CommunityImport] that reads from the member's VTA.
  CommunityImport(this._vta);

  final VtaClient _vta;

  /// Returns the membership card [communityDid] issued to [personaDid], as
  /// the VTA keeps it, or null when it holds none, e.g. while the
  /// community has yet to deliver it.
  ///
  /// Asks the VTA for that card only: every card it finds is fetched on its
  /// own, and a member of many communities would wait for each. Each step
  /// is reported to [onStep] as it starts.
  Future<Map<String, dynamic>?> membershipCard(
    String communityDid, {
    required String personaDid,
    void Function(MembershipCardStep step)? onStep,
  }) async {
    onStep?.call(MembershipCardStep.finding);
    final records = await _vta.credentialRecords(
      _membershipPurpose,
      issuerDid: communityDid,
      subjectDid: personaDid,
    );
    if (records.isEmpty) return null;
    onStep?.call(MembershipCardStep.reading);
    for (final record in records) {
      final card = await _vta.credential(record.id);
      if (card != null && _isCard(card, communityDid, personaDid)) return card;
    }
    return null;
  }

  /// Returns the role, e.g. `member` or `moderator`, that [communityDid]
  /// grants [personaDid] in the newest valid role card the VTA keeps, or
  /// null when it holds none, e.g. while the community has yet to deliver
  /// it. The community re-issues the card on every role change, so the
  /// newest is the role in force. A vetter card is held alongside that
  /// role, e.g. by an administrator, so it stands for the role only when
  /// the VTA keeps no other.
  Future<String?> role(
    String communityDid, {
    required String personaDid,
  }) async {
    final held = await _vta.findCredentials(
      type: _roleCardType,
      issuerDid: communityDid,
      subjectDid: personaDid,
    );
    final newestFirst = [...held]
      ..sort((a, b) => _issuedAt(b).compareTo(_issuedAt(a)));
    String? heldAlongside;
    for (final record in newestFirst) {
      final card = await _vta.credential(record.id);
      if (card == null) continue;
      switch (roleOf(card, communityDid, personaDid)) {
        case vetterRole:
          heldAlongside ??= vetterRole;
        case final role?:
          return role;
        case null:
      }
    }
    return heldAlongside;
  }

  /// Returns the newest role card in which [communityDid] makes
  /// [personaDid] a vetter, as the VTA keeps it, when it holds at [now] and
  /// [statusList] reads it as not revoked. Null when there is none: a card
  /// without a revocation status cannot be shown to hold, so it does not.
  ///
  /// Throws [MeetingPlaceVtcSDKException] when the status list cannot be
  /// read.
  Future<Map<String, dynamic>?> vetterCard(
    String communityDid, {
    required String personaDid,
    required StatusListClient statusList,
    DateTime? now,
  }) async {
    final held = await _vta.findCredentials(
      type: _roleCardType,
      issuerDid: communityDid,
      subjectDid: personaDid,
    );
    final newestFirst = [...held]
      ..sort((a, b) => _issuedAt(b).compareTo(_issuedAt(a)));
    for (final record in newestFirst) {
      final card = await _vta.credential(record.id);
      if (card == null ||
          !grantsCommunityRole(
            card,
            communityDid: communityDid,
            holderDid: personaDid,
            role: vetterRole,
          ) ||
          !roleCardInDate(card, now ?? DateTime.now())) {
        continue;
      }
      final status = await statusList.check(card);
      if (status.state == CredentialStatusState.valid) return card;
    }
    return null;
  }

  static DateTime _issuedAt(HeldCredential record) =>
      record.validFrom ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  /// The role [card] grants [personaDid] in [communityDid], or null when
  /// the community did not issue it about that persona. Does not verify
  /// the card.
  static String? roleOf(
    Map<String, dynamic> card,
    String communityDid,
    String personaDid,
  ) {
    if (credentialIssuer(card) != communityDid) return null;
    final subject = card['credentialSubject'];
    for (final entry in subject is List ? subject : [subject]) {
      if (entry case {
        'id': final String id,
        'authority': {
          'scope': final String scope,
          'actions': final List<dynamic> actions,
        },
      } when id == personaDid && scope == communityDid) {
        for (final action in actions.whereType<String>()) {
          if (action.startsWith(_roleActionPrefix)) {
            return action.substring(_roleActionPrefix.length);
          }
        }
      }
    }
    return null;
  }

  /// Every membership card the VTA holds, of any community and persona,
  /// each with the VTA's record of it.
  Future<List<StoredCredential>> membershipCards() =>
      _vta.storedCredentials(_membershipPurpose);

  /// Archives the membership cards [communityDid] issued to [personaDid] on
  /// the VTA, once the persona left: neither [find] nor another app of the
  /// member then takes the persona for a member.
  ///
  /// Asks the VTA for those cards only, as [membershipCard] does.
  Future<void> archiveMembershipCards(
    String communityDid, {
    required String personaDid,
  }) async {
    final cards = await _vta.storedCredentials(
      _membershipPurpose,
      issuerDid: communityDid,
      subjectDid: personaDid,
    );
    for (final stored in cards) {
      if (_isCard(stored.credential, communityDid, personaDid)) {
        await _vta.archiveCredential(stored.record.id);
      }
    }
  }

  static bool _isCard(
    Map<String, dynamic> card,
    String communityDid,
    String personaDid,
  ) =>
      credentialIssuer(card) == communityDid &&
      credentialSubjects(card).contains(personaDid);

  /// Returns the membership in [communityDid], or null when no backed-up
  /// card issued by that community names one of the VTA's personas.
  ///
  /// Asks the VTA for that community's cards only, as [membershipCard]
  /// does: a member of many communities would otherwise wait for each.
  Future<CommunityMembership?> find(String communityDid) async {
    final cards = await _vta.credentials(
      _membershipPurpose,
      issuerDid: communityDid,
    );
    final issuedHere = cards.where(
      (card) => credentialIssuer(card) == communityDid,
    );
    if (issuedHere.isEmpty) return null;

    final personas = await _vta.listPersonas();
    for (final card in issuedHere) {
      final subjects = credentialSubjects(card);
      for (final persona in personas) {
        if (subjects.contains(persona.did)) {
          return CommunityMembership(
            communityDid: communityDid,
            persona: persona,
            name: card['name'] is String ? card['name'] as String : null,
          );
        }
      }
    }
    return null;
  }
}
