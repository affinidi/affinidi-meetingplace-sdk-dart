import 'dart:convert';
import 'dart:math';

/// [count] cryptographically random bytes.
List<int> randomBytes(int count) {
  final random = Random.secure();
  return [for (var i = 0; i < count; i++) random.nextInt(256)];
}

/// [count] random bytes, base64url without padding, as vetting's secrets,
/// salts and challenges are written.
String randomBase64Url(int count) =>
    base64Url.encode(randomBytes(count)).replaceAll('=', '');
