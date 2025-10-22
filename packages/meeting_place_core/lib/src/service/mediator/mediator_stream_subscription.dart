import 'dart:async';
import 'mediator_message.dart';

/// Interface for mediator stream subscriptions.
///
/// Provides a stream of [MediatorMessage]s and lifecycle management.
abstract class MediatorStreamSubscription {
  /// Stream of transformed mediator messages.
  ///
  /// Messages are automatically decrypted and transformed based on their type.
  /// Group messages are decrypted using keys from the key repository.
  Stream<MediatorMessage> get stream;

  /// Check if the underlying subscription is closed.
  bool get isClosed;

  /// Dispose the subscription and close the connection.
  ///
  /// After calling this method, the stream will be closed and no more
  /// messages will be received. The underlying mediator connection will
  /// be disconnected.
  Future<void> dispose();
}
