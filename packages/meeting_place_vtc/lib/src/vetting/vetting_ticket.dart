/// A vetter's ticket: what lets an applicant ask that vetter to vet them
/// for a community. Read from the QR code a vetter shows,
///
/// ```text
/// vetting-ticket:?v=1&community=<DID>&vetter=<DID>&ticket=<id>&secret=<secret>
/// vetting-ticket:?v=1&community=<DID>&vetter=<DID>&code=K7QF-2M9X
/// ```
///
/// or made from a code the vetter reads out, once the applicant has picked
/// the vetter ([VettingTicket.spoken]).
///
/// A vetter mints one with `VetterTicket.mint`.
///
/// It carries no expiry and no proof of the vetter's role: the vetter keeps
/// the first to themselves and presents the second when they accept.
class VettingTicket {
  const VettingTicket._({
    required this.community,
    required this.vetter,
    this.ticketId,
    this.secret,
    this.code,
  });

  /// The QR form of a ticket a vetter minted (`VetterTicket`).
  const VettingTicket.scanned({
    required String community,
    required String vetter,
    required String ticketId,
    required String secret,
  }) : this._(
         community: community,
         vetter: vetter,
         ticketId: ticketId,
         secret: secret,
       );

  /// The spoken form of a ticket a vetter minted (`VetterTicket`).
  const VettingTicket.withCode({
    required String community,
    required String vetter,
    required String code,
  }) : this._(community: community, vetter: vetter, code: code);

  /// The scheme of a ticket URI.
  static const scheme = 'vetting-ticket';

  /// The ticket URI version this wallet reads.
  static const version = '1';

  /// A ticket for the [code] the vetter [vetter] read out, or null when
  /// [code] is not one. Reads it the way people type it: any case, with or
  /// without the dash, spaces left out.
  static VettingTicket? spoken({
    required String community,
    required String vetter,
    required String code,
  }) {
    final typed = code.replaceAll(RegExp(r'\s'), '').toUpperCase();
    final dashed = typed.length == 8
        ? '${typed.substring(0, 4)}-${typed.substring(4)}'
        : typed;
    if (!_code.hasMatch(dashed) || !_did.hasMatch(community)) return null;
    if (!_did.hasMatch(vetter)) return null;
    return VettingTicket._(community: community, vetter: vetter, code: dashed);
  }

  /// Reads the ticket URI [input], or returns null when it is none: another
  /// scheme or version, a member repeated or malformed, a fragment, or both
  /// forms of ticket or neither. Members it does not know are ignored.
  static VettingTicket? parse(String input) {
    final trimmed = input.trim();
    final colon = trimmed.indexOf(':');
    if (colon < 0 ||
        trimmed.substring(0, colon).toLowerCase() != scheme ||
        !trimmed.startsWith('?', colon + 1) ||
        trimmed.contains('#')) {
      return null;
    }

    final members = <String, String>{};
    for (final pair in trimmed.substring(colon + 2).split('&')) {
      if (pair.isEmpty) continue;
      final equals = pair.indexOf('=');
      if (equals < 0) return null;
      final name = pair.substring(0, equals);
      if (!_members.contains(name)) continue;
      if (members.containsKey(name)) return null;
      final value = pair.substring(equals + 1);
      if (_badEscape.hasMatch(value)) return null;
      try {
        members[name] = Uri.decodeComponent(value);
      } on FormatException {
        return null;
      }
    }

    final community = members['community'];
    final vetter = members['vetter'];
    if (members['v'] != version ||
        community == null ||
        !_did.hasMatch(community) ||
        vetter == null ||
        !_did.hasMatch(vetter)) {
      return null;
    }
    return switch ((members['ticket'], members['secret'], members['code'])) {
      (final String id, final String secret, null)
          when _ticketId.hasMatch(id) && _secret.hasMatch(secret) =>
        VettingTicket._(
          community: community,
          vetter: vetter,
          ticketId: id,
          secret: secret,
        ),
      (null, null, final String code) when _code.hasMatch(code) =>
        VettingTicket._(community: community, vetter: vetter, code: code),
      _ => null,
    };
  }

  /// The community the vetter vets for.
  final String community;

  /// The vetter's DID.
  final String vetter;

  /// The scanned ticket's id, or null for a spoken code.
  final String? ticketId;

  /// The scanned ticket's secret, or null for a spoken code.
  final String? secret;

  /// The spoken code, e.g. `K7QF-2M9X`, or null for a scanned ticket.
  final String? code;

  /// The ticket as `vetting/request/0.1` carries it.
  Map<String, dynamic> toJson() =>
      code != null ? {'code': code} : {'ticketId': ticketId, 'secret': secret};

  /// The ticket as a URI, members percent-encoded.
  @override
  String toString() {
    final members = {
      'v': version,
      'community': community,
      'vetter': vetter,
      if (code != null)
        'code': code
      else ...{
        'ticket': ticketId,
        'secret': secret,
      },
    };
    final query = [
      for (final MapEntry(:key, :value) in members.entries)
        '$key=${Uri.encodeComponent('$value')}',
    ];
    return '$scheme:?${query.join('&')}';
  }

  static const _members = {
    'v',
    'community',
    'vetter',
    'ticket',
    'secret',
    'code',
  };
  static final _badEscape = RegExp('%(?![0-9A-Fa-f]{2})');
  static final _did = RegExp(r'^did:[a-z0-9]+:\S+$');
  static final _ticketId = RegExp(r'^[A-Za-z0-9._:-]{1,128}$');
  static final _secret = RegExp(r'^[A-Za-z0-9_-]{43}$');
  static final _code = RegExp(r'^[0-9A-HJKMNP-TV-Z]{4}-[0-9A-HJKMNP-TV-Z]{4}$');
}
