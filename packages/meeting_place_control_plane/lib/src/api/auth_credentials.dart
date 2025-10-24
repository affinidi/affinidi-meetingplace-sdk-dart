/// A model class that holds the authentication tokens used by [ControlPlaneSDK]
/// to authenticate API calls.
class AuthCredentials {
  /// Creates a new instance of [AuthCredentials] with all required fields.
  ///
  /// **Parameters:**
  /// - [accessToken]: The access token string.
  /// - [refreshToken]: The refresh token string.
  /// - [accessExpiresAt]: The expiration time of the access token.
  /// - [refreshExpiresAt]: The expiration time of the refresh token.
  AuthCredentials({
    required this.accessToken,
    required this.refreshToken,
    required this.accessExpiresAt,
    required this.refreshExpiresAt,
  });
  final String accessToken;
  final String refreshToken;
  final DateTime refreshExpiresAt;
  final DateTime accessExpiresAt;
}
