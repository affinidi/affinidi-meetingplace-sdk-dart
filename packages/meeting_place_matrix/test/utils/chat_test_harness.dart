import 'dart:async';

import 'package:meeting_place_chat/meeting_place_chat.dart';

/// Helpers for integration tests that subscribe to a [MeetingPlaceChatSDK]'s
/// event stream. Replaces ad-hoc `Completer<void>` + `stream.listen` patterns
/// with typed, named waits whose timeout errors point at the calling test.
abstract final class ChatTestHarness {
  /// Resolves with the first emitted [ChatEvent] of type [T] (optionally
  /// matching [where]). Throws [TimeoutException] if nothing matches within
  /// [timeout]. The error message names [T] so failures point at the test.
  static Future<T> awaitEvent<T extends ChatEvent>(
    MeetingPlaceChatSDK sdk, {
    Duration timeout = const Duration(seconds: 30),
    bool Function(T)? where,
  }) async {
    final stream = await sdk.chatStreamSubscription;
    if (stream == null) {
      throw StateError(
        'chatStreamSubscription is null — did you call startChatSession?',
      );
    }
    final completer = Completer<T>();
    late final StreamSubscription<StreamData> sub;
    sub = stream.stream.listen((data) {
      final event = data.event;
      if (event is! T) return;
      if (where != null && !where(event)) return;
      if (!completer.isCompleted) completer.complete(event);
    });
    try {
      return await completer.future.timeout(
        timeout,
        onTimeout: () => throw TimeoutException(
          'Timed out waiting for $T after ${timeout.inSeconds}s',
        ),
      );
    } finally {
      await sub.cancel();
    }
  }

  /// Resolves with the first emitted [StreamData] whose [ChatItem] satisfies
  /// [where] (or any chat item if [where] is null). Throws on timeout.
  static Future<ChatItem> awaitItem(
    MeetingPlaceChatSDK sdk, {
    bool Function(ChatItem)? where,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final stream = await sdk.chatStreamSubscription;
    if (stream == null) {
      throw StateError(
        'chatStreamSubscription is null — did you call startChatSession?',
      );
    }
    final completer = Completer<ChatItem>();
    late final StreamSubscription<StreamData> sub;
    sub = stream.stream.listen((data) {
      final item = data.chatItem;
      if (item == null) return;
      if (where != null && !where(item)) return;
      if (!completer.isCompleted) completer.complete(item);
    });
    try {
      return await completer.future.timeout(
        timeout,
        onTimeout: () => throw TimeoutException(
          'Timed out waiting for ChatItem after ${timeout.inSeconds}s',
        ),
      );
    } finally {
      await sub.cancel();
    }
  }

  /// Collects every emitted [StreamData] across [duration]. Useful when a
  /// test needs to assert on a count or absence of events.
  static Future<List<StreamData>> collect(
    MeetingPlaceChatSDK sdk, {
    required Duration duration,
  }) async {
    final stream = await sdk.chatStreamSubscription;
    if (stream == null) {
      throw StateError(
        'chatStreamSubscription is null — did you call startChatSession?',
      );
    }
    final collected = <StreamData>[];
    final sub = stream.stream.listen(collected.add);
    await Future<void>.delayed(duration);
    await sub.cancel();
    return collected;
  }
}
