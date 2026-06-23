import 'dart:async';

import 'package:test/test.dart';

/// Wraps [test] in a [runZonedGuarded] that swallows the known post-test
/// async race in `didcomm` 2.3.3 — `Connection.start` schedules an unawaited
/// `fetchMessages().then(...)` whose callback adds to a `StreamController`
/// after our dispose chain has already closed it, producing:
///
///     Bad state: Cannot add new events after calling close
///     package:didcomm/src/mediator_client/connection.dart 183:29
///         Connection.start.<fn>.<fn>.<fn>
///
/// The error fires after the test has completed and after we've cleanly
/// torn down our subscription, so it cannot be caught by `tearDown`. Only
/// this specific error is swallowed; all other async errors propagate as
/// test failures.
void testWithDidcommGuard(
  String description,
  Future<void> Function() body, {
  Timeout? timeout,
  Object? skip,
  Object? tags,
}) {
  test(
    description,
    () {
      final completer = Completer<void>();
      runZonedGuarded(
        () async {
          try {
            await body();
            if (!completer.isCompleted) completer.complete();
          } catch (error, stackTrace) {
            if (!completer.isCompleted) {
              completer.completeError(error, stackTrace);
            }
          }
        },
        (error, stackTrace) {
          if (_isDidcommPostCloseRace(error, stackTrace)) {
            return;
          }
          if (!completer.isCompleted) {
            completer.completeError(error, stackTrace);
          }
        },
      );
      return completer.future;
    },
    timeout: timeout,
    skip: skip,
    tags: tags,
  );
}

bool _isDidcommPostCloseRace(Object error, StackTrace stackTrace) {
  if (error is! StateError) return false;
  if (!error.message.contains('Cannot add new events after calling close')) {
    return false;
  }
  return stackTrace.toString().contains(
    'package:didcomm/src/mediator_client/connection.dart',
  );
}
