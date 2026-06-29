import 'package:meeting_place_matrix/src/chat/typing_indicator_manager.dart';
import 'package:meeting_place_chat/src/logger/meeting_place_chat_sdk_logger.dart';
import 'package:test/test.dart';

class _NoOpLogger implements MeetingPlaceChatSDKLogger {
  @override
  void info(String message, {String name = ''}) {}
  @override
  void warning(String message, {String name = ''}) {}
  @override
  void debug(String message, {String name = ''}) {}
  @override
  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String name = '',
  }) {}
}

void main() {
  const expiry = Duration(milliseconds: 120);

  TypingIndicatorManager build({
    required List<bool> calls,
    Exception? throwOn,
  }) {
    return TypingIndicatorManager(
      onSetTypingState: (active) async {
        calls.add(active);
        if (throwOn != null) throw throwOn;
      },
      expiry: expiry,
      logger: _NoOpLogger(),
    );
  }

  test('first sendActivity sends typing=true', () async {
    final calls = <bool>[];
    final manager = build(calls: calls);

    await manager.sendActivity();

    expect(calls, [true]);
  });

  test('subsequent sendActivity calls within expiry do not resend', () async {
    final calls = <bool>[];
    final manager = build(calls: calls);

    await manager.sendActivity();
    await manager.sendActivity();
    await manager.sendActivity();

    expect(calls, [true]);
  });

  test(
    'stop() before keep-alive fires prevents keep-alive from sending',
    () async {
      final calls = <bool>[];
      final manager = build(calls: calls);

      await manager.sendActivity();
      manager.stop();

      // Wait past the keep-alive interval (2/3 of expiry = 80ms)
      await Future<void>.delayed(expiry);

      expect(calls, [true]); // only the initial send
    },
  );

  test('keep-alive resends typing=true before expiry', () async {
    final calls = <bool>[];
    final manager = build(calls: calls);

    await manager.sendActivity();

    // Wait for keep-alive interval to fire (2/3 of 120ms = 80ms)
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(calls, [true, false, true]);

    manager.stop();
  });

  test('keep-alive reschedules itself while active', () async {
    final calls = <bool>[];
    final manager = TypingIndicatorManager(
      onSetTypingState: (active) async => calls.add(active),
      expiry: const Duration(milliseconds: 60),
      logger: _NoOpLogger(),
    );

    await manager.sendActivity();

    // Keep resetting the auto-stop so it doesn't cut short the keep-alive
    // cycles
    await Future<void>.delayed(const Duration(milliseconds: 30));
    await manager.sendActivity();
    await Future<void>.delayed(const Duration(milliseconds: 30));
    await manager.sendActivity();
    await Future<void>.delayed(const Duration(milliseconds: 100));

    // Initial send + ≥2 keep-alives
    expect(calls.length, greaterThanOrEqualTo(3));

    manager.stop();
  });

  test(
    'keep-alive error sets manager to inactive and stops rescheduling',
    () async {
      final calls = <bool>[];
      var throwNext = false;
      final manager = TypingIndicatorManager(
        onSetTypingState: (active) async {
          calls.add(active);
          if (throwNext) throw Exception('network error');
        },
        expiry: expiry,
        logger: _NoOpLogger(),
      );

      await manager.sendActivity();
      throwNext = true;

      // Wait for keep-alive to fire and fail
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // No further keep-alive calls after the error
      final countAfterError = calls.length;
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(calls.length, equals(countAfterError));
    },
  );

  test('stop() after expiry is a no-op', () async {
    final calls = <bool>[];
    final manager = build(calls: calls);

    await manager.sendActivity();
    await Future<void>.delayed(expiry * 2);
    manager.stop(); // should not throw
  });

  test('sendActivity after stop() starts a new typing session', () async {
    final calls = <bool>[];
    final manager = build(calls: calls);

    await manager.sendActivity();
    manager.stop();
    await manager.sendActivity();

    expect(calls, [true, true]);
  });
}
