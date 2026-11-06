import 'dart:typed_data';

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
    this.thumbnail,
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
      thumbnail: _withinCap(values[_thumbnail]),
    );
  }

  /// The longest [thumbnail] a profile carries, in characters of base64.
  ///
  /// Every profile read and write carries the thumbnail, so it is kept small
  /// next to the VTA's 1 MB request cap.
  static const maxThumbnailLength = 48 * 1024;

  static const _displayName = 'name.display';
  static const _firstName = 'name.given';
  static const _lastName = 'name.family';
  static const _email = 'email.personal';
  static const _mobile = 'phone.mobile';

  /// The VTA's claim-type registry has no picture type yet, so the thumbnail
  /// uses the open extension namespace. The VTA treats an `x:` type as
  /// unregistered: high sensitivity, released only with consent.
  static const _thumbnail = 'x:photo.thumbnail';

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

  /// Picture of the identity, as a base64-encoded JPEG of at most
  /// [maxThumbnailLength] characters.
  final String? thumbnail;

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
    if (_present(thumbnail) case final value?)
      (_thumbnail, 'avatar', _checkedThumbnail(value)),
  ];

  static String _checkedThumbnail(String value) {
    if (value.length > maxThumbnailLength) {
      throw ArgumentError.value(
        value.length,
        'thumbnail',
        'longer than $maxThumbnailLength characters',
      );
    }
    return value;
  }

  /// A thumbnail over the cap, as another client of the VTA may write one, is
  /// dropped rather than handed on to be decoded.
  static String? _withinCap(String? value) =>
      value != null && value.length <= maxThumbnailLength ? value : null;

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

/// A credential the vault holds, as a query describes it: no claim content.
class HeldCredential {
  /// Creates a [HeldCredential].
  const HeldCredential({
    required this.id,
    required this.types,
    this.issuerDid,
    this.validFrom,
    this.validUntil,
    this.purpose,
    this.status,
  });

  /// The vault's own handle for it, which the VTA client's `credential`
  /// and `presentCredential` take.
  final String id;

  /// Its VC `type` tags.
  final List<String> types;

  /// The DID that issued it, when the vault says.
  final String? issuerDid;

  /// When it starts being valid, when it says.
  final DateTime? validFrom;

  /// When it stops being valid, when it says.
  final DateTime? validUntil;

  /// What the vault files it under, e.g. `membership`, when it knows.
  final String? purpose;

  /// Whether the vault holds it valid, e.g. `valid`, `expired`, `revoked`
  /// or `unknown`, as it last read its issuer's status.
  final String? status;
}

/// A credential the vault holds: the vault's record of it, and the
/// credential itself.
class StoredCredential {
  /// Creates a [StoredCredential].
  const StoredCredential({required this.record, required this.credential});

  /// What the vault keeps about it.
  final HeldCredential record;

  /// The credential exactly as the vault keeps it.
  final Map<String, dynamic> credential;
}

/// A credential presented to one verifier (`vault/credentials/present/0.1`).
class CredentialPresentation {
  /// Creates a [CredentialPresentation].
  const CredentialPresentation({
    required this.presentation,
    required this.disclosed,
  });

  /// The holder-signed W3C presentation, to carry to the verifier unchanged.
  final Map<String, dynamic> presentation;

  /// The names of the subject claims it discloses.
  final List<String> disclosed;
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

/// A key the member's VTA holds for a Meeting Place connection DID. Only
/// its public half is kept on this device.
class VtaConnectionKey {
  /// Creates a [VtaConnectionKey].
  const VtaConnectionKey({required this.keyId, required this.publicKey});

  /// The VTA's id of the key, which `VtaClient.signDocument` and
  /// `VtaClient.lendConnectionKey` name.
  final String keyId;

  /// The public key: 32 bytes for Ed25519, 33 compressed bytes for P-256.
  final Uint8List publicKey;
}

/// One application record the VTA keeps in a context (`vta/app-state`).
class AppStateRecord {
  /// Creates an [AppStateRecord].
  const AppStateRecord({
    required this.key,
    required this.version,
    required this.value,
  });

  /// Reads a record as `vta/app-state/list` returns it.
  factory AppStateRecord.fromJson(Map<String, dynamic> json) => AppStateRecord(
    key: json['key'] as String,
    version: json['version'] as int,
    value: json['value'],
  );

  /// The record's key within its namespace.
  final String key;

  /// The version its latest write took.
  final int version;

  /// The stored JSON.
  final Object? value;
}
