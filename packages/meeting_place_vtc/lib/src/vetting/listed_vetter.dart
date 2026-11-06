import 'vetting_requirements.dart';

/// A vetter a community lists for applicants to find
/// (`vtc/vetting/vetters/list/0.1`).
///
/// Everything but [did] is what the vetter wrote about themselves and is
/// unverified: show it as theirs. Their role is checked when they accept a
/// request, not here.
class ListedVetter {
  /// Creates a [ListedVetter].
  const ListedVetter({
    required this.did,
    required this.methods,
    this.displayName,
    this.languages = const [],
    this.place,
    this.acceptsDocumentation = const [],
    this.events = const [],
    this.availability,
    this.contactHint,
  });

  /// Reads one listed vetter, or returns null when it names no DID or no
  /// method this wallet knows.
  static ListedVetter? read(Object? json) {
    if (json is! Map) return null;
    final did = json['vetterDid'];
    final byName = VettingMethod.values.asNameMap();
    final methods = [
      for (final name in _strings(json['methods']))
        if (byName[name] case final VettingMethod method) method,
    ];
    if (did is! String || !did.startsWith('did:') || methods.isEmpty) {
      return null;
    }
    return ListedVetter(
      did: did,
      methods: methods,
      displayName: _string(json['displayName']),
      languages: _strings(json['languages']),
      place: _place(json['location']),
      acceptsDocumentation: _strings(json['acceptsDocumentation']),
      events: [
        for (final event
            in json['events'] is List ? json['events'] as List : [])
          if (event is Map) ?_string(event['name']),
      ],
      availability: _string(json['availability']),
      contactHint: _string(json['contactHint']),
    );
  }

  /// The vetter's member DID, the one a vetting request goes to.
  final String did;

  /// The methods the vetter offers.
  final List<VettingMethod> methods;

  /// The name the vetter is listed under, if they gave one.
  final String? displayName;

  /// The languages the vetter speaks, as BCP 47 tags.
  final List<String> languages;

  /// Where the vetter meets people, coarsest last, e.g. `Berlin, BE, DE`.
  final String? place;

  /// The documentation the vetter relies on, in lowerCamelCase, e.g.
  /// `passport`, `nationalId`, `driverLicence`, or `none`.
  final List<String> acceptsDocumentation;

  /// The names of the events the vetter will vet at, not yet ended.
  final List<String> events;

  /// When the vetter is available, in their words.
  final String? availability;

  /// How to get a ticket from the vetter, in their words.
  final String? contactHint;

  static String? _place(Object? location) {
    if (location is! Map) return null;
    final parts = [
      for (final part in ['city', 'region', 'country'])
        ?_string(location[part]),
    ];
    return parts.isEmpty ? null : parts.join(', ');
  }

  static String? _string(Object? value) =>
      value is String && value.trim().isNotEmpty ? value.trim() : null;

  static List<String> _strings(Object? value) =>
      value is List ? value.whereType<String>().toList() : const [];
}
