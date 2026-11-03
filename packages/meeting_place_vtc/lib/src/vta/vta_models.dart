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
