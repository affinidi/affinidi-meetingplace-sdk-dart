abstract final class LivenessZkpConciergeIds {
  static String requestReceived(String attachmentMessageId) =>
      'zkp-request-received-$attachmentMessageId';

  static String proofShared(String attachmentMessageId) =>
      'zkp-proof-shared-$attachmentMessageId';

  static String proofReceived(String attachmentMessageId) =>
      'zkp-proof-received-$attachmentMessageId';

  static String paused({required String forRequestNoticeMessageId}) =>
      'zkp-paused-$forRequestNoticeMessageId';

  static String pausedEphemeral(String uniqueSuffix) =>
      'zkp-paused-$uniqueSuffix';
}
