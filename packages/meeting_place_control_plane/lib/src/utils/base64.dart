import 'dart:convert';

String toBase64(Map<String, dynamic> json) {
  return base64UrlEncode(utf8.encode(jsonEncode(json)));
}
