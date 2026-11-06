/// The Crockford base32 alphabet vetting codes are written in.
const crockfordAlphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

/// The first 40 bits of [bytes] as a vetting code, `XXXX-XXXX` in Crockford
/// base32.
String crockfordCode(List<int> bytes) {
  // 40 bits: past what bitwise operators hold on the web.
  final bits = bytes
      .take(5)
      .fold(BigInt.zero, (bits, byte) => (bits << 8) | BigInt.from(byte));
  final code = [
    for (var i = 0; i < 8; i++)
      crockfordAlphabet[((bits >> (35 - 5 * i)) & BigInt.from(31)).toInt()],
  ].join();
  return '${code.substring(0, 4)}-${code.substring(4)}';
}
