/// Formats [time] as an RFC 3339 UTC timestamp with whole seconds, e.g.
/// `2026-10-11T07:33:00Z`.
///
/// Trust Task documents and their proofs carry no fractional seconds.
String formatTrustTaskTime(DateTime time) {
  final iso = time.toUtc().toIso8601String();
  return '${iso.substring(0, iso.indexOf('.'))}Z';
}
