import 'r_card_subject.dart';

/// Codec for the RFC 7095 jCard format used to embed contact data
/// in R-Card VCs.
///
/// See https://datatracker.ietf.org/doc/html/rfc7095 for the jCard specification
/// and https://datatracker.ietf.org/doc/html/rfc6350 for the underlying vCard 4.0
/// property vocabulary.
class JCard {
  JCard._();

  /// Encodes an [RCardSubject] to an RFC 7095 jCard list structure.
  ///
  /// **Property names are camelCase** (e.g. `firstName`, `profilePic`) rather
  /// than the RFC 6350 vocabulary names (`n`, `photo`, `url`). This is
  /// intentional for compatibility with the H2H decoder which uses the same
  /// camelCase convention. The `version` property is always emitted first as
  /// required by RFC 7095. Only non-empty fields are included.
  ///
  /// Output format:
  /// `['vcard', [['version',{},'text','4.0'], ['fn',{},'text','...'], ...]]`.
  static List<Object> encode(RCardSubject subject) {
    final entries = <List<Object>>[
      ['version', const <String, dynamic>{}, 'text', '4.0'],
    ];

    void addText(String prop, String? value) {
      final v = value?.trim();
      if (v != null && v.isNotEmpty) {
        entries.add([prop, const <String, dynamic>{}, 'text', v]);
      }
    }

    addText('firstName', subject.firstName);
    addText('lastName', subject.lastName);
    addText('email', subject.email);
    addText('phone', subject.phone);
    addText('profilePic', subject.profilePic);
    addText('company', subject.company);
    addText('position', subject.position);
    addText('website', subject.website);
    addText('social', subject.social);

    return ['vcard', entries];
  }

  /// Decodes a jCard list into a flat map suitable for [RCardSubject.fromJson].
  ///
  /// Maps standard RFC 6350 property names to [RCardSubject] field names.
  /// Unknown property names are passed through as-is for backward compatibility
  /// with older VCs that used camelCase names.
  ///
  /// Returns `null` if [card] is not a valid jCard structure.
  static Map<String, dynamic>? decode(dynamic card, String? id) {
    if (card is! List || card.length < 2 || card[0] != 'vcard') return null;
    final props = card[1];
    if (props is! List) return null;

    final result = <String, dynamic>{'id': id};
    for (final p in props) {
      if (p is! List || p.length < 4 || p[0] == null) continue;
      final name = p[0].toString();
      final value = p[3];
      switch (name) {
        case 'version':
        case 'fn':
          // skip: version is metadata; fn is derived from the n property
          break;
        case 'n':
          // Structured name: [family, given, additional, prefix, suffix]
          if (value is List) {
            result['lastName'] = _trim(value.isNotEmpty ? value[0] : null);
            result['firstName'] = _trim(value.length > 1 ? value[1] : null);
          }
        case 'email':
          result['email'] = _trim(value);
        case 'tel':
          result['phone'] = _trim(value);
        case 'photo':
          result['profilePic'] = _trim(value);
        case 'org':
          result['company'] = _trim(value);
        case 'title':
          result['position'] = _trim(value);
        case 'url':
          result['website'] = _trim(value);
        case 'x-socialprofile':
          result['social'] = _trim(value);
        default:
          // Backward compat: pass through legacy camelCase property names.
          result[name] = _trim(value);
      }
    }
    return result;
  }

  static String? _trim(dynamic v) {
    final s = v?.toString().trim();
    return s != null && s.isNotEmpty ? s : null;
  }
}
