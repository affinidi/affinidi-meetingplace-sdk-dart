import 'r_card_subject.dart';

/// Codec for the jCard format used to embed contact data in R-Card VCs.
///
/// The wire format is the 4-tuple array structure defined by RFC 7095
/// (https://datatracker.ietf.org/doc/html/rfc7095). Property names are
/// camelCase (e.g. `firstName`, `profilePic`) rather than RFC 6350 vocabulary
/// names; [decode] also recognises standard RFC 6350 aliases for
/// interoperability with externally-encoded vCards.
class JCard {
  JCard._();

  /// Encodes an [RCardSubject] to an RFC 7095 jCard list structure.
  ///
  /// **Property names are camelCase** (e.g. `firstName`, `profilePic`) rather
  /// than the RFC 6350 vocabulary names (`n`, `photo`, `url`). The `version`
  /// property is always emitted first as required by RFC 7095. Only non-empty
  /// fields are included.
  ///
  /// Output format:
  /// `['vcard', [['version',{},'text','4.0'], ['firstName',{},'text','...'], ...]]`.
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
  /// Recognises the camelCase property names written by [encode] and maps
  /// standard RFC 6350 aliases (`n`, `tel`, `photo`, `org`, `title`, `url`)
  /// to the corresponding [RCardSubject] field names for interoperability.
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
        case 'fn':
          // skip: version is metadata; fn is a display-name alias not used by encode
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
        case 'social':
          result['social'] = _trim(value);
        default:
          // Pass through non-standard property names as-is.
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
