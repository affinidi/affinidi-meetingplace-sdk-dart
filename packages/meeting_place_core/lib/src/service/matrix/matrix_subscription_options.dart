class MatrixSubscriptionOptions {
  /// If true, the SDK will not emit events for messages sent by the user
  /// themselves.
  final bool excludeSelf;

  /// Creates a new [MatrixSubscriptionOptions] instance.
  const MatrixSubscriptionOptions({this.excludeSelf = false});
}
