import 'dart:convert';

import 'matrix_token.dart' show MatrixTokenCommand;

/// The result returned when a Matrix login token is requested.
typedef GetMatrixTokenResult = MatrixTokenCommandOutput;

/// Output of [MatrixTokenCommand].
class MatrixTokenCommandOutput {
  /// Creates a new instance of [MatrixTokenCommandOutput].
  MatrixTokenCommandOutput({required this.token});

  /// The decoded Matrix login token issued for the requesting DID.
  final MatrixLoginToken token;
}

class MatrixLoginToken {
  /// Creates a new instance of [MatrixLoginToken].
  MatrixLoginToken({
    required this.iss,
    required this.sub,
    required this.aud,
    required this.exp,
    required this.iat,
    required this.jti,
    required String rawJwt,
  }) : _rawJwt = rawJwt;

  /// Decodes a [MatrixLoginToken] from the payload of a raw JWT string.
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

  /// The issuer claim (`iss`) of the JWT.
  final String iss;

  /// The subject claim (`sub`) of the JWT, identifying the token holder.
  final String sub;

  /// The audience claim (`aud`) of the JWT.
  final String aud;

  /// The expiration claim (`exp`) of the JWT.
  final String exp;

  /// The issued-at claim (`iat`) of the JWT.
  final String iat;

  /// The JWT ID claim (`jti`) of the JWT.
  final String jti;
  final String _rawJwt;
}
