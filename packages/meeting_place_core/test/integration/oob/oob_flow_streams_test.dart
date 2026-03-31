import 'dart:async';

import 'package:meeting_place_core/meeting_place_core.dart';
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

      expect(resultA.stream, isNot(equals(resultB.stream)));
    });

    test('uses separate stream for each acceptOobFlow call', () async {
      final createOobFlowResult = await fixture.createOobFlow();

      final resultA = await fixture.acceptOobFlow(createOobFlowResult.oobUrl);
      final resultB = await fixture.acceptOobFlow(createOobFlowResult.oobUrl);

      expect(resultA.stream, isNot(equals(resultB.stream)));
    });

    test('executes callback on timeout', () async {
      final createOobFlowResult = await fixture.createOobFlow();

      final aliceCompleter = Completer<String>();

      createOobFlowResult.stream.listen((data) => data);
      createOobFlowResult.stream.timeout(
        const Duration(milliseconds: 200),
        () => aliceCompleter.complete('timeout'),
      );

      expect(await aliceCompleter.future, equals('timeout'));
    });

    test('cancels timeout after receiving first event', () async {
      final createOobFlowResult = await fixture.createOobFlow();
      await fixture.acceptOobFlow(createOobFlowResult.oobUrl);

      final firstEventReceived = Completer<OobStreamData>();
      createOobFlowResult.stream.listen(firstEventReceived.complete);

      createOobFlowResult.stream.timeout(
        const Duration(seconds: 3),
        () => fail('timeout executed'),
      );

      final event = await firstEventReceived.future.timeout(
        const Duration(seconds: 10),
      );
      expect(event, isA<OobStreamData>());
    });
  });
}
