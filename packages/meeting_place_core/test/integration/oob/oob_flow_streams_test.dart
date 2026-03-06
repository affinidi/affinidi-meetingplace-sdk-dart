import 'dart:async';

import 'package:test/test.dart';

import '../utils/oob_flow_fixture.dart';

void main() {
  group('stream subscriptions', () {
    late OobFlowFixture fixture;

    setUp(() async {
      fixture = await OobFlowFixture.create();
    });

    test('uses separate stream for each createOobFlow call', () async {
      final resultA = await fixture.createOobFlow();
      final resultB = await fixture.createOobFlow();

      expect(
        resultA.streamSubscription,
        isNot(equals(resultB.streamSubscription)),
      );
    });

    test('uses separate stream for each acceptOobFlow call', () async {
      final createOobFlowResult = await fixture.createOobFlow();

      final resultA = await fixture.acceptOobFlow(createOobFlowResult.oobUrl);
      final resultB = await fixture.acceptOobFlow(createOobFlowResult.oobUrl);

      expect(
        resultA.streamSubscription,
        isNot(equals(resultB.streamSubscription)),
      );
    });

    test('executes callback on timeout', () async {
      final createOobFlowResult = await fixture.createOobFlow();

      final aliceCompleter = Completer<String>();

      createOobFlowResult.streamSubscription.listen((data) => data);
      createOobFlowResult.streamSubscription.timeout(
        const Duration(milliseconds: 200),
        () => aliceCompleter.complete('timeout'),
      );

      expect(await aliceCompleter.future, equals('timeout'));
    });

    test('cancels timeout after receiving first event', () async {
      final createOobFlowResult = await fixture.createOobFlow();

      await fixture.acceptOobFlow(createOobFlowResult.oobUrl);

      createOobFlowResult.streamSubscription.listen((data) => data);
      createOobFlowResult.streamSubscription.timeout(
        const Duration(seconds: 1),
        () => fail('timeout executed'),
      );

      await Future.delayed(const Duration(seconds: 2));
    }, skip: 'flaky test on CI');
  });
}
