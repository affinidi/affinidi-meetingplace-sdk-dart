import 'dart:async';

/// Interface for mediator stream subscriptions.
///
/// Provides a stream of [T]s and lifecycle management.
abstract class CoreSDKStreamSubscription<T, S> {
  /// Stream of transformed mediator messages.
  ///
  /// Messages are automatically decrypted and transformed based on their type.
  /// Group messages are decrypted using keys from the key repository.
  Stream<T> get stream;

  /// Check if the underlying subscription is closed.
  bool get isClosed;

  /// Listen to the stream of messages.
  ///
  /// The [onData] callback is called for each message.
  ///
  /// If multiple listeners are attached, the message is deleted if
  /// any listener returns a result with `keepMessage: false`.
  StreamSubscription<T> listen(
    FutureOr<S> Function(T) onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  });

  /// Apply a timeout to the stream subscription.
  StreamSubscription<T> timeout(Duration timeLimit, void Function()? onTimeout);

  /// Dispose the subscription and close the connection.
  ///
  /// After calling this method, the stream will be closed and no more
  /// messages will be received. The underlying mediator connection will
  /// be disconnected.
  Future<void> dispose();
}
