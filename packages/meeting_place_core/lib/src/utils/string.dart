import 'dart:convert';

extension TopAndTailExtension on String {
  String topAndTail({int charCountTop = 16, int charCountTail = 8}) {
    if (length < charCountTop || length - charCountTail < 0) {
      return this;
    }
    return """${substring(0, charCountTop)}${(charCountTop > 0) ? '...' : ''}${substring(length - charCountTail)}""";
  }
}

String toBase64(Map<String, dynamic> json) {
  return base64UrlEncode(utf8.encode(jsonEncode(json)));
}

Map<String, dynamic> fromBase64(String base64) {
  return jsonDecode(utf8.decode(base64Decode(base64))) as Map<String, dynamic>;
}
