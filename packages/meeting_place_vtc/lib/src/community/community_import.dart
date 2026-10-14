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

  /// Returns the membership in [communityDid], or null when no backed-up
  /// card issued by that community names one of the VTA's personas.
  Future<CommunityMembership?> find(String communityDid) async {
    final cards = await _vta.credentials(_membershipPurpose);
    final issuedHere = cards.where((card) => _issuer(card) == communityDid);
    if (issuedHere.isEmpty) return null;

    final personas = await _vta.listPersonas();
    for (final card in issuedHere) {
      final subjects = _subjects(card);
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

  static String? _issuer(Map<String, dynamic> card) {
    return switch (card['issuer']) {
      final String id => id,
      {'id': final String id} => id,
      _ => null,
    };
  }

  static Set<String> _subjects(Map<String, dynamic> card) {
    final subject = card['credentialSubject'];
    final subjects = subject is List ? subject : [subject];
    return {
      for (final entry in subjects)
        if (entry case {'id': final String id}) id,
    };
  }
}
