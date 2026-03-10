import 'package:test/test.dart';

import 'utils/mediator_integration_fixture.dart';

void main() {
  late MediatorIntegrationFixture fixture;

  setUp(() async {
    fixture = await MediatorIntegrationFixture.create();
  });

  test(
    'handles multiple subscriptions to mediator gracefully returning a new instance',
    () async {
      final subscriptionA = await fixture.sdk.subscribeToMessages(
        fixture.didManagerA,
      );
      final subscriptionB = await fixture.sdk.subscribeToMessages(
        fixture.didManagerA,
      );

      expect(subscriptionA, isNot(equals(subscriptionB)));
    },
  );

  test(
    'Multiple authentications with the same did return the different mediator client instances',
    () async {
      final clientA =
          await fixture.sdk.authenticateWithDid(fixture.didManagerA);
      final clientB =
          await fixture.sdk.authenticateWithDid(fixture.didManagerA);

      expect(clientA, isNot(equals(clientB)));
    },
  );

  test('Multiple authentications with the same did use the same session',
      () async {
    final clientA = await fixture.sdk.authenticateWithDid(fixture.didManagerA);
    final clientB = await fixture.sdk.authenticateWithDid(fixture.didManagerA);

    expect(
      clientA.authorizationProvider,
      equals(clientB.authorizationProvider),
    );
  });

  test('Uses new mediator session if did is not cached', () async {
    final sessionA = await fixture.sdk.authenticateWithDid(fixture.didManagerA);
    final sessionB = await fixture.sdk.authenticateWithDid(fixture.didManagerB);
    expect(sessionA, isNot(equals(sessionB)));
  });
}
