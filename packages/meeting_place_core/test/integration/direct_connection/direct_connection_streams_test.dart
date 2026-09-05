@Tags(['integration'])
library;

import 'dart:async';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:test/test.dart';

import '../utils/direct_connection_fixture.dart';

void main() {
  group('stream subscriptions', () {
    late DirectConnectionFixture fixture;

    setUpAll(() async {
      fixture = await DirectConnectionFixture.create();
    });

    test('uses separate stream for each createDirectConnection call', () async {
      final resultA = await fixture.createDirectConnection();
      final resultB = await fixture.createDirectConnection();

      expect(resultA.stream, isNot(equals(resultB.stream)));
    });

    test('uses separate stream for each acceptDirectConnection call', () async {
      final createDirectConnectionResult = await fixture
          .createDirectConnection();

      final resultA = await fixture.acceptDirectConnection(
        createDirectConnectionResult.directConnectionUrl,
      );
      final resultB = await fixture.acceptDirectConnection(
        createDirectConnectionResult.directConnectionUrl,
      );

      expect(resultA.stream, isNot(equals(resultB.stream)));
    });

    test('executes callback on timeout', () async {
      final createDirectConnectionResult = await fixture
          .createDirectConnection();

      final aliceCompleter = Completer<String>();

      createDirectConnectionResult.stream.listen((data) => data);
      createDirectConnectionResult.stream.timeout(
        const Duration(milliseconds: 200),
        () => aliceCompleter.complete('timeout'),
      );

      expect(await aliceCompleter.future, equals('timeout'));
    });

    test('cancels timeout after receiving first event', () async {
      final createDirectConnectionResult = await fixture
          .createDirectConnection();
      await fixture.acceptDirectConnection(
        createDirectConnectionResult.directConnectionUrl,
      );

      final firstEventReceived = Completer<DirectConnectionStreamData>();
      createDirectConnectionResult.stream.listen(firstEventReceived.complete);

      createDirectConnectionResult.stream.timeout(
        const Duration(seconds: 3),
        () => fail('timeout executed'),
      );

      final event = await firstEventReceived.future.timeout(
        const Duration(seconds: 10),
      );
      expect(event, isA<DirectConnectionStreamData>());
    });
  });
}
