class MediatorSession {
  const MediatorSession({
    required this.accessToken,
    required this.accessExpiresAt,
    required this.refreshToken,
    required this.refreshExpiresAt,
    this.secondsBeforeExpiryReauthenticate,
  });
  static const defaultSecondsBeforeExpiryReauthenticate = 60;

  final String accessToken;
  final DateTime accessExpiresAt;
  final String refreshToken;
  final DateTime refreshExpiresAt;
  final int? secondsBeforeExpiryReauthenticate;

  bool isValid() {
    return accessExpiresAt.isAfter(
      DateTime.now().toUtc().add(
            Duration(
              seconds: secondsBeforeExpiryReauthenticate ??
                  defaultSecondsBeforeExpiryReauthenticate,
            ),
          ),
    );
  }
}
