import 'dart:convert';

/// Output of `MatrixTokenCommand`.
class MatrixTokenCommandOutput {
  MatrixTokenCommandOutput({required this.token});

  final MatrixLoginToken token;
}

class MatrixLoginToken {
  MatrixLoginToken({
    required this.iss,
    required this.sub,
    required this.aud,
    required this.exp,
    required this.iat,
    required this.jti,
    required String rawJwt,
  }) : _rawJwt = rawJwt;

  factory MatrixLoginToken.fromJwt(String jwt) {
    final parts = jwt.split('.');
    if (parts.length != 3) {
      throw const FormatException('Invalid JWT format');
    }
    // Base64url decode the payload (pad to a multiple of 4 if needed)
    final payload = parts[1];
    final normalized = base64Url.normalize(payload);
    final decoded = utf8.decode(base64Url.decode(normalized));
    final json = jsonDecode(decoded) as Map<String, dynamic>;
    return MatrixLoginToken(
      iss: json['iss'] as String,
      sub: json['sub'] as String,
      aud: json['aud'] as String,
      exp: json['exp'].toString(),
      iat: json['iat'].toString(),
      jti: json['jti'] as String,
      rawJwt: jwt,
    );
  }

  String toJwt() => _rawJwt;

  final String iss;
  final String sub;
  final String aud;
  final String exp;
  final String iat;
  final String jti;
  final String _rawJwt;
}
