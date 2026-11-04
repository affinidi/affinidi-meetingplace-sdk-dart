/// A persona whose keys the member's VTA holds: one `did:webvh` per
/// community.
class VtaPersona {
  /// Creates a [VtaPersona]. [signingKeyId] defaults to the `#key-0` the VTA
  /// names a persona's signing key.
  const VtaPersona({
    required this.did,
    required this.contextId,
    String? signingKeyId,
  }) : _signingKeyId = signingKeyId;

  /// The persona's DID.
  final String did;

  /// The VTA context the persona lives in.
  final String contextId;

  final String? _signingKeyId;

  /// Id of the persona's signing key on the VTA.
  String get signingKeyId => _signingKeyId ?? '$did#key-0';
}

/// The details an identity shows of itself, kept as a profile on the
/// member's VTA.
///
/// Every value is self-asserted and kept in the identity's own context, so no
/// other identity can come to present it.
class VtaProfile {
  /// Creates a [VtaProfile].
  const VtaProfile({
    required this.displayName,
    required this.firstName,
    this.lastName,
    this.email,
    this.mobile,
  });

  /// Reads a profile from its entries, as the VTA returns them.
  factory VtaProfile.fromEntries(Object? entries) {
    final values = <String, String>{};
    if (entries is List) {
      for (final entry in entries.whereType<Map<String, dynamic>>()) {
        final inline = entry['inline'];
        if (inline is Map<String, dynamic> &&
            inline['type'] is String &&
            inline['value'] is String) {
          values[inline['type'] as String] = inline['value'] as String;
        }
      }
    }
    return VtaProfile(
      displayName: values[_displayName] ?? '',
      firstName: values[_firstName] ?? '',
      lastName: values[_lastName],
      email: values[_email],
      mobile: values[_mobile],
    );
  }

  static const _displayName = 'name.display';
  static const _firstName = 'name.given';
  static const _lastName = 'name.family';
  static const _email = 'email.personal';
  static const _mobile = 'phone.mobile';

  /// What the identity calls itself.
  final String displayName;

  /// Given name.
  final String firstName;

  /// Family name.
  final String? lastName;

  /// Email address.
  final String? email;

  /// Mobile number.
  final String? mobile;

  /// The profile's values as claims typed now, for composing it.
  List<Map<String, dynamic>> toClaims() => [
    for (final (type, slot, value) in _values)
      {
        'type': type,
        'valueType': 'string',
        'value': value,
        'share': 'local',
        'slot': ?slot,
      },
  ];

  /// The profile's values as context-local entries, for updating it.
  List<Map<String, dynamic>> toEntries() => [
    for (final (type, slot, value) in _values)
      {
        'inline': {'type': type, 'valueType': 'string', 'value': value},
        'slot': ?slot,
      },
  ];

  List<(String, String?, String)> get _values => [
    (_displayName, 'displayName', displayName),
    (_firstName, null, firstName),
    if (_present(lastName) case final value?) (_lastName, null, value),
    if (_present(email) case final value?) (_email, 'primaryEmail', value),
    if (_present(mobile) case final value?) (_mobile, 'primaryPhone', value),
  ];

  static String? _present(String? value) =>
      value == null || value.trim().isEmpty ? null : value;
}

/// An identity held by the member's VTA: a persona DID in a context of its
/// own, wearing a profile kept in that context.
///
/// Holds references only. The persona's keys never leave the VTA.
class VtaIdentity {
  /// Creates a [VtaIdentity].
  const VtaIdentity({
    required this.persona,
    required this.profileId,
    required this.profile,
  });

  /// The persona the identity is.
  final VtaPersona persona;

  /// Id of the profile the persona wears.
  final String profileId;

  /// The profile's details.
  final VtaProfile profile;
}

/// What the member's VTA lets this phone's manager key do, as its `whoami`
/// answer states it.
class VtaAccess {
  /// Creates a [VtaAccess].
  const VtaAccess({required this.roles, required this.capabilities});

  /// Reads the `roles` and effective `capabilities` of a `whoami` answer.
  factory VtaAccess.fromWhoAmI(Map<String, dynamic> payload) => VtaAccess(
    roles: _strings(payload['roles']),
    capabilities: _strings(payload['capabilities']),
  );

  /// Role the phone needs on the VTA.
  static const adminRole = 'admin';

  /// Capability the phone needs to hold identities as personas. No role
  /// carries it: the VTA's super-admin grants it by name.
  static const personaHolder = 'persona-holder';

  /// Roles the VTA holds for the manager key.
  final Set<String> roles;

  /// Capabilities the VTA holds for the manager key, as it enforces them.
  final Set<String> capabilities;

  /// Whether the manager key is an admin.
  bool get isAdmin => roles.contains(adminRole);

  /// Whether the manager key may hold personas.
  bool get holdsPersonas => capabilities.contains(personaHolder);

  /// Whether the VTA granted all this phone needs.
  bool get isGranted => isAdmin && holdsPersonas;

  static Set<String> _strings(Object? list) => switch (list) {
    final List<dynamic> items => items.whereType<String>().toSet(),
    _ => const {},
  };
}

/// A claim the VTA would disclose about a persona, as a disclosure preview
/// shows it.
class DisclosedClaim {
  /// Creates a [DisclosedClaim].
  const DisclosedClaim({required this.type, this.value, this.stale = false});

  /// The claim type, e.g. `name`.
  final String type;

  /// The value that would be disclosed, or null when the VTA holds none or
  /// discloses only a predicate.
  final Object? value;

  /// Whether the VTA flags the value as out of date.
  final bool stale;
}

/// What the VTA would disclose about a persona to a verifier
/// (`persona/disclosure/preview/1.0`), awaiting the member's approval.
class DisclosurePreview {
  /// Creates a [DisclosurePreview].
  const DisclosurePreview({required this.previewId, required this.claims});

  /// The preview's id, to present it once approved.
  final String previewId;

  /// The claims the preview covers.
  final List<DisclosedClaim> claims;
}
