import '../credentials/credential_fields.dart';

/// The role a community grants the members who may vet applicants.
const vetterRole = 'vetter';

/// Whether [card] is [communityDid]'s own grant of [role] to [holderDid]:
/// an `AuthorityCredential` it issued as itself (`issuerScope` `public`),
/// not attenuated from another, scoped to the community. Does not verify
/// the card.
bool grantsCommunityRole(
  Map<String, dynamic> card, {
  required String communityDid,
  required String holderDid,
  required String role,
}) {
  if (!credentialTypes(card).contains('AuthorityCredential') ||
      credentialIssuer(card) != communityDid ||
      card['issuerScope'] != 'public') {
    return false;
  }
  final subject = card['credentialSubject'];
  return switch (subject) {
    {
      'id': final String id,
      'authority':
          {
            'scope': final String scope,
            'actions': final List<dynamic> actions,
          } &&
          final Map<String, dynamic> authority,
    } =>
      id == holderDid &&
          scope == communityDid &&
          authority['parent'] == null &&
          actions.any((action) => _roleMatches(action, role)),
    _ => false,
  };
}

/// Whether role [card] holds at [now], give or take [skew]. A role card is
/// bounded: one without `validUntil` is taken not to hold rather than to
/// hold for ever.
bool roleCardInDate(
  Map<String, dynamic> card,
  DateTime now, {
  Duration skew = Duration.zero,
}) {
  final validFrom = DateTime.tryParse('${card['validFrom']}');
  final validUntil = DateTime.tryParse('${card['validUntil']}');
  return validUntil != null &&
      !now.isAfter(validUntil.add(skew)) &&
      (validFrom == null || !validFrom.isAfter(now.add(skew)));
}

/// Whether the action `role:<held>` grants [required]: equal, or both the
/// vetter role with or without the `custom:` prefix.
bool _roleMatches(Object? action, String required) {
  if (action is! String || !action.startsWith('role:')) return false;
  String bare(String role) =>
      role.startsWith('custom:') ? role.substring('custom:'.length) : role;
  final held = action.substring('role:'.length);
  return held == required ||
      (bare(held) == vetterRole && bare(required) == vetterRole);
}
