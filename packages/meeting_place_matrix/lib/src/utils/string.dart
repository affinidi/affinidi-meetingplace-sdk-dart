/// String utilities for safe logging.
extension TopAndTailExtension on String {
  /// Returns a truncated representation safe for log output.
  ///
  /// Keeps the first [charCountTop] and last [charCountTail] characters,
  /// joining them with `...`. Useful for logging DIDs and other long
  /// identifiers without exposing the full value.
  ///
  /// Returns the original string unchanged if it is shorter than
  /// [charCountTop] or if the tail slice would underflow.
  ///
  /// Example: `'did:key:zABCDEFG...XYZ'` → `'did:key:zABCDEFG...WXYZ'`
  String topAndTail({int charCountTop = 16, int charCountTail = 8}) {
    if (length < charCountTop || length - charCountTail < 0) return this;
    final ellipsis = charCountTop > 0 ? '...' : '';
    final tail = substring(length - charCountTail);
    return '${substring(0, charCountTop)}$ellipsis$tail';
  }
}
