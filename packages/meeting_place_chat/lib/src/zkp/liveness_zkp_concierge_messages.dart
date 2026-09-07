import 'package:uuid/uuid.dart';

import 'model/liveness_zkp_concierge_ids.dart';
import 'model/liveness_zkp_concierge_notice.dart';
import 'model/liveness_zkp_concierge_types.dart';

/// Factories for human ZKP concierge notices.
abstract final class LivenessZkpConciergeMessages {
  /// Builds the notice shown when [contactName] has requested a human
  /// liveness ZKP proof from the current user.
  static LivenessZkpConciergeNotice humanZkpRequest({
    required String chatId,
    required String messageId,
    required DateTime dateCreated,
    required String contactName,
  }) {
    return LivenessZkpConciergeNotice(
      chatId: chatId,
      messageId: messageId,
      dateCreated: dateCreated,
      conciergeType: LivenessZkpConciergeTypes.humanZkpRequest,
      isFromMe: false,
      data: {'contactName': contactName},
    );
  }

  /// Builds the notice shown when the current user has sent a human
  /// liveness ZKP request to the other party.
  static LivenessZkpConciergeNotice humanZkpRequestInitiated({
    required String chatId,
    required String messageId,
    required DateTime dateCreated,
  }) {
    return LivenessZkpConciergeNotice(
      chatId: chatId,
      messageId: messageId,
      dateCreated: dateCreated,
      conciergeType: LivenessZkpConciergeTypes.humanZkpRequestInitiated,
      isFromMe: true,
    );
  }

  /// Builds the notice shown while the human liveness ZKP flow is paused.
  ///
  /// The notice id is derived from [pausedForRequestNoticeMessageId] via
  /// [LivenessZkpConciergeIds.paused] when set, so it replaces the paused
  /// state for that specific request. Otherwise it is derived from
  /// [ephemeralSuffix] (or a generated UUID) via
  /// [LivenessZkpConciergeIds.pausedEphemeral] for a one-off, non-request-tied
  /// pause.
  static LivenessZkpConciergeNotice humanZkpPaused({
    required String chatId,
    required DateTime dateCreated,
    String? pausedForRequestNoticeMessageId,
    String? ephemeralSuffix,
  }) {
    final messageId = pausedForRequestNoticeMessageId != null
        ? LivenessZkpConciergeIds.paused(
            forRequestNoticeMessageId: pausedForRequestNoticeMessageId,
          )
        : LivenessZkpConciergeIds.pausedEphemeral(
            ephemeralSuffix ?? const Uuid().v4(),
          );

    return LivenessZkpConciergeNotice(
      chatId: chatId,
      messageId: messageId,
      dateCreated: dateCreated,
      conciergeType: LivenessZkpConciergeTypes.humanZkpPaused,
      isFromMe: true,
    );
  }

  /// Builds the notice shown when the current user has shared a human
  /// liveness ZKP proof with the other party.
  static LivenessZkpConciergeNotice humanZkpProofShared({
    required String chatId,
    required String messageId,
    required DateTime dateCreated,
  }) {
    return LivenessZkpConciergeNotice(
      chatId: chatId,
      messageId: messageId,
      dateCreated: dateCreated,
      conciergeType: LivenessZkpConciergeTypes.humanZkpProofShared,
      isFromMe: true,
    );
  }

  /// Builds the notice shown when [contactName] has shared a human liveness
  /// ZKP proof with the current user.
  static LivenessZkpConciergeNotice humanZkpProofReceived({
    required String chatId,
    required String messageId,
    required DateTime dateCreated,
    required String contactName,
  }) {
    return LivenessZkpConciergeNotice(
      chatId: chatId,
      messageId: messageId,
      dateCreated: dateCreated,
      conciergeType: LivenessZkpConciergeTypes.humanZkpProofReceived,
      isFromMe: false,
      data: {'contactName': contactName},
    );
  }

  /// Builds the notice shown when [contactName] has declined a human
  /// liveness ZKP request from the current user.
  static LivenessZkpConciergeNotice humanZkpDeclinedReceived({
    required String chatId,
    required String messageId,
    required DateTime dateCreated,
    required String contactName,
  }) {
    return LivenessZkpConciergeNotice(
      chatId: chatId,
      messageId: messageId,
      dateCreated: dateCreated,
      conciergeType: LivenessZkpConciergeTypes.humanZkpDeclined,
      isFromMe: false,
      data: {'contactName': contactName},
    );
  }
}
