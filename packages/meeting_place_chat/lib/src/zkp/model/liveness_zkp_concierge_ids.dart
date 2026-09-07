/// Concierge message IDs for human liveness ZKP.
abstract final class LivenessZkpConciergeIds {
  /// Builds the notice id for a human ZKP request received from the other
  /// party, derived from the [attachmentMessageId] that carried it.
  static String requestReceived(String attachmentMessageId) =>
      'zkp-request-received-$attachmentMessageId';

  /// Builds the notice id for a human ZKP request initiated by the current
  /// user, derived from the [attachmentMessageId] that carried it.
  static String requestInitiated(String attachmentMessageId) =>
      'zkp-request-initiated-$attachmentMessageId';

  /// Builds the notice id for a human ZKP proof shared by the current user,
  /// derived from the [attachmentMessageId] that carried it.
  static String proofShared(String attachmentMessageId) =>
      'zkp-proof-shared-$attachmentMessageId';

  /// Builds the notice id for a human ZKP proof received from the other
  /// party, derived from the [attachmentMessageId] that carried it.
  static String proofReceived(String attachmentMessageId) =>
      'zkp-proof-received-$attachmentMessageId';

  /// Builds the notice id for a human ZKP request declined by the other
  /// party, derived from the [attachmentMessageId] that carried it.
  static String declinedReceived(String attachmentMessageId) =>
      'zkp-declined-received-$attachmentMessageId';

  /// Builds the notice id for the paused state tied to the request notice
  /// identified by [forRequestNoticeMessageId], so it replaces that specific
  /// request's paused state.
  static String paused({required String forRequestNoticeMessageId}) =>
      'zkp-paused-$forRequestNoticeMessageId';

  /// Builds the notice id for a one-off paused state not tied to a specific
  /// request notice, derived from [uniqueSuffix].
  static String pausedEphemeral(String uniqueSuffix) =>
      'zkp-paused-$uniqueSuffix';
}
