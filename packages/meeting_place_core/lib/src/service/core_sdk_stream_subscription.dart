import 'dart:async';

/// Interface for mediator stream subscriptions.
///
/// Provides a stream of [T]s and lifecycle management.
abstract class CoreSDKStreamSubscription<T> {
  /// Stream of transformed mediator messages.
  ///
  /// Messages are automatically decrypted and transformed based on their type.
  /// Group messages are decrypted using keys from the key repository.
  Stream<T> get stream;

  /// Check if the underlying subscription is closed.
  bool get isClosed;

  /// Listen to the stream of messages.
  StreamSubscription<T> listen(
    void Function(T) onData, {
    Function(Object e)? onError,
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
