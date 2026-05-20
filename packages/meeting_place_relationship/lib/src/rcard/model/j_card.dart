import 'r_card_subject.dart';

/// Codec for the jCard format used to embed contact data in R-Card VCs.
///
/// The wire format and property vocabulary follow RFC 7095
/// (https://datatracker.ietf.org/doc/html/rfc7095) and RFC 6350
/// (https://datatracker.ietf.org/doc/html/rfc6350).
class JCard {
  JCard._();

  /// Encodes an [RCardSubject] to an RFC 7095 / RFC 6350 compliant jCard.
  ///
  /// Property names and value types follow the RFC 6350 vocabulary:
  /// - `fn` (mandatory §6.2.1): formatted display name derived from
  ///   first + last name.
  /// - `n` (§6.2.2): structured name
  ///   `[family, given, additional, prefix, suffix]`.
  /// - `email`, `tel`, `org`, `title`: `"text"` values.
  /// - `photo`, `url`: `"uri"` values (RFC 6350 §6.2.4 / §6.7.8).
  /// - `x-socialprofile`: extension property (RFC 6350 §6.10) for social URL.
  ///
  /// `version` is always emitted first as required by RFC 7095 §3.3.
  /// Only non-empty fields are included.
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

    void addUri(String prop, String? value) {
      final v = value?.trim();
      if (v != null && v.isNotEmpty) {
        entries.add([prop, const <String, dynamic>{}, 'uri', v]);
      }
    }

    // fn is mandatory in every vCard (RFC 6350 §6.2.1).
    // Always emit it even when both names are absent.
    final givenName = subject.firstName?.trim() ?? '';
    final familyName = subject.lastName?.trim() ?? '';
    final formattedName = [
      givenName,
      familyName,
    ].where((s) => s.isNotEmpty).join(' ');
    entries.add(['fn', const <String, dynamic>{}, 'text', formattedName]);

    // n: structured name [family, given, additional, prefix, suffix]
    if (givenName.isNotEmpty || familyName.isNotEmpty) {
      entries.add([
        'n',
        const <String, dynamic>{},
        'text',
        [familyName, givenName, '', '', ''],
      ]);
    }

    addText('email', subject.email);
    addText('tel', subject.phone);
    addUri('photo', subject.profilePic);
    addText('org', subject.company);
    addText('title', subject.position);
    addUri('url', subject.website);
    addText('x-socialprofile', subject.social);

    return ['vcard', entries];
  }

  /// Decodes a jCard list into a flat map suitable for
  /// `RCardCredentialSubject.fromJson`.
  ///
  /// Maps RFC 6350 property names to `RCardCredentialSubject` field names.
  /// Unknown property names are passed through as-is.
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
          break;
        case 'fn':
          // formatted name — used as fallback when n is absent
          result['name'] = _trim(value);
        case 'n':
          // Structured name: [family, given, additional, prefix, suffix]
          if (value is List) {
            result['lastName'] = _trim(value.isNotEmpty ? value[0] : null);
            result['firstName'] = _trim(value.length > 1 ? value[1] : null);
            result['additionalName'] = _trim(
              value.length > 2 ? value[2] : null,
            );
            result['prefix'] = _trim(value.length > 3 ? value[3] : null);
            result['suffix'] = _trim(value.length > 4 ? value[4] : null);
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
          // Pass through unknown property names as-is.
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
