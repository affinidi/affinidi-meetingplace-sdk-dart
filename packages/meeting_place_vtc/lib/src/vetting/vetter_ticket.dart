import 'dart:convert';
import 'dart:math';

import 'crockford_code.dart';
import 'vetting_ticket.dart';

/// A ticket as the vetter who minted it keeps it: what an applicant's
/// `vetting/request` must name, scanned ([scanned]) or read out ([spoken]),
/// and how often and how long it still may.
///
/// Tickets stay on the vetter's phone; the community never sees them.
class VetterTicket {
  /// Creates a [VetterTicket].
  const VetterTicket({
    required this.id,
    required this.code,
    required this.secret,
    required this.community,
    required this.vetter,
    required this.usesLeft,
    required this.expiresAt,
  });

  /// A fresh ticket for [community] that [vetter] shows: a random id,
  /// secret and code, good for [uses] requests until [validity] has passed.
  ///
  /// Throws [ArgumentError] when [uses] or [validity] is not positive.
  factory VetterTicket.mint({
    required String community,
    required String vetter,
    int uses = defaultUses,
    Duration validity = defaultValidity,
    DateTime? now,
  }) {
    if (uses < 1) throw ArgumentError.value(uses, 'uses', 'not positive');
    if (validity <= Duration.zero) {
      throw ArgumentError.value(validity, 'validity', 'not positive');
    }
    final random = Random.secure();
    List<int> bytes(int count) => [
      for (var i = 0; i < count; i++) random.nextInt(256),
    ];
    final hex = bytes(16).map((b) => b.toRadixString(16).padLeft(2, '0'));
    return VetterTicket(
      id: 'vt-${hex.join()}',
      code: crockfordCode(bytes(5)),
      secret: base64Url.encode(bytes(32)).replaceAll('=', ''),
      community: community,
      vetter: vetter,
      usesLeft: uses,
      expiresAt: (now ?? DateTime.now()).toUtc().add(validity),
    );
  }

  /// Reads a ticket [toJson] wrote.
  factory VetterTicket.fromJson(Map<String, dynamic> json) => VetterTicket(
    id: json['id'] as String,
    code: json['code'] as String,
    secret: json['secret'] as String,
    community: json['community'] as String,
    vetter: json['vetter'] as String,
    usesLeft: json['usesLeft'] as int,
    expiresAt: DateTime.parse(json['expiresAt'] as String),
  );

  /// The requests a ticket is good for unless the vetter says otherwise.
  static const defaultUses = 1;

  /// How long a ticket lasts unless the vetter says otherwise.
  static const defaultValidity = Duration(days: 14);

  /// The ticket's id, `vt-` and 32 hex digits.
  final String id;

  /// The code the vetter reads out, e.g. `K7QF-2M9X`.
  final String code;

  /// The secret the QR code carries: 32 random bytes, base64url.
  final String secret;

  /// The community the ticket is for.
  final String community;

  /// The vetter's DID.
  final String vetter;

  /// The requests the ticket may still be accepted for.
  final int usesLeft;

  /// When the ticket stops being accepted.
  final DateTime expiresAt;

  /// The ticket as the vetter's QR code shows it.
  VettingTicket get scanned => VettingTicket.scanned(
    community: community,
    vetter: vetter,
    ticketId: id,
    secret: secret,
  );

  /// The ticket as the vetter reads it out.
  VettingTicket get spoken =>
      VettingTicket.withCode(community: community, vetter: vetter, code: code);

  /// Whether the ticket may still be accepted at [now].
  bool isLive(DateTime now) => usesLeft > 0 && now.isBefore(expiresAt);

  /// Whether [ticket], as a `vetting/request` carries it, names this ticket
  /// and it is still live at [now]. Compares without stopping at the first
  /// difference, and reads a code the way people type it.
  bool admits(Map<String, dynamic> ticket, DateTime now) {
    if (!isLive(now)) return false;
    return switch (ticket) {
      {'code': final String typed} => _sameText(
        normaliseVettingCode(typed) ?? '',
        code,
      ),
      {'ticketId': final String ticketId, 'secret': final String sent} =>
        // Both compared, so the time taken does not tell which differed.
        _sameText(ticketId, id) & _sameText(sent, secret),
      _ => false,
    };
  }

  /// This ticket once a request has been accepted for it.
  VetterTicket spent() => VetterTicket(
    id: id,
    code: code,
    secret: secret,
    community: community,
    vetter: vetter,
    usesLeft: usesLeft - 1,
    expiresAt: expiresAt,
  );

  /// The ticket as [VetterTicket.fromJson] reads it.
  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'secret': secret,
    'community': community,
    'vetter': vetter,
    'usesLeft': usesLeft,
    'expiresAt': expiresAt.toUtc().toIso8601String(),
  };
}

/// Reads a code the way people type it: any case, with or without the dash
/// or spaces, and the letters Crockford reads as digits (`O` → `0`, `I`/`L`
/// → `1`). Null when [input] cannot be a code.
String? normaliseVettingCode(String input) {
  final chars = StringBuffer();
  for (final char in input.toUpperCase().split('')) {
    final digit = switch (char) {
      '-' || ' ' => null,
      'O' => '0',
      'I' || 'L' => '1',
      _ => char,
    };
    if (digit == null) continue;
    if (!crockfordAlphabet.contains(digit)) return null;
    chars.write(digit);
  }
  final code = chars.toString();
  if (code.length != 8) return null;
  return '${code.substring(0, 4)}-${code.substring(4)}';
}

/// Whether [a] and [b] are equal, without stopping at the first difference.
bool _sameText(String a, String b) {
  final left = utf8.encode(a);
  final right = utf8.encode(b);
  var difference = left.length ^ right.length;
  for (var i = 0; i < left.length; i++) {
    difference |= left[i] ^ (i < right.length ? right[i] : 0);
  }
  return difference == 0;
}
