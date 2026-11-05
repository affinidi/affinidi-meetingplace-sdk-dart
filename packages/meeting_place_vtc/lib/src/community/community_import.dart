import '../credentials/credential_fields.dart';
import '../vta/vta_client.dart';
import '../vta/vta_models.dart';

/// Vault purpose of membership credentials.
const _membershipPurpose = 'membership';

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
  Future<Map<String, dynamic>?> membershipCard(
    String communityDid, {
    required String personaDid,
  }) async {
    final cards = await _vta.credentials(_membershipPurpose);
    return cards
        .where((card) => _isCard(card, communityDid, personaDid))
        .firstOrNull;
  }

  /// Every membership card the VTA holds, of any community and persona,
  /// each with the VTA's record of it.
  Future<List<StoredCredential>> membershipCards() =>
      _vta.storedCredentials(_membershipPurpose);

  /// Archives the membership cards [communityDid] issued to [personaDid] on
  /// the VTA, once the persona left: neither [find] nor another app of the
  /// member then takes the persona for a member.
  Future<void> archiveMembershipCards(
    String communityDid, {
    required String personaDid,
  }) async {
    final cards = await _vta.heldCredentials(_membershipPurpose);
    for (final MapEntry(key: id, value: card) in cards.entries) {
      if (_isCard(card, communityDid, personaDid)) {
        await _vta.archiveCredential(id);
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
  Future<CommunityMembership?> find(String communityDid) async {
    final cards = await _vta.credentials(_membershipPurpose);
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
