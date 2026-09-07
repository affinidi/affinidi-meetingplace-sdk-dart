import 'mediator_stream_subscription.dart' show MediatorStreamSubscription;

/// The outcome of processing a single message delivered by
/// [MediatorStreamSubscription.listen]'s `onData` callback.
class MediatorStreamProcessingResult {
  /// Creates a [MediatorStreamProcessingResult].
  MediatorStreamProcessingResult({required this.keepMessage});

  /// Whether the processed message should be kept on the mediator instead of
  /// being scheduled for deletion.
  final bool keepMessage;
}
