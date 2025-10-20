import 'package:meeting_place_mediator/src/core/mediator/mediator_session.dart';
import 'package:test/test.dart';

void main() {
  test(
    'isValid returns true when accessExpiresAt is sufficiently in the future',
    () {
      final session = MediatorSession(
        accessToken: 'token',
        accessExpiresAt: DateTime.now().toUtc().add(Duration(minutes: 2)),
        refreshToken: 'refresh',
        refreshExpiresAt: DateTime.now().toUtc().add(Duration(days: 1)),
      );

      expect(session.isValid(), isTrue);
    },
  );

  test('isValid returns false when accessExpiresAt is too close to now', () {
    final session = MediatorSession(
      accessToken: 'token',
      accessExpiresAt: DateTime.now().toUtc().add(Duration(seconds: 30)),
      refreshToken: 'refresh',
      refreshExpiresAt: DateTime.now().toUtc().add(Duration(days: 1)),
    );
    expect(session.isValid(), isFalse);
  });

  test('isValid respects custom secondsBeforeExpiryReauthenticate', () {
    final session = MediatorSession(
      accessToken: 'token',
      accessExpiresAt: DateTime.now().toUtc().add(Duration(seconds: 50)),
      refreshToken: 'refresh',
      refreshExpiresAt: DateTime.now().toUtc().add(Duration(days: 1)),
      secondsBeforeExpiryReauthenticate: 40,
    );
    expect(session.isValid(), isTrue);
  });

  test('isValid returns false when accessExpiresAt is before now', () {
    final session = MediatorSession(
      accessToken: 'token',
      accessExpiresAt: DateTime.now().toUtc().subtract(Duration(seconds: 10)),
      refreshToken: 'refresh',
      refreshExpiresAt: DateTime.now().toUtc().add(Duration(days: 1)),
    );
    expect(session.isValid(), isFalse);
  });
}
