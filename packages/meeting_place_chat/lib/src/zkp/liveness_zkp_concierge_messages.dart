import 'package:uuid/uuid.dart';

import 'model/liveness_zkp_concierge_ids.dart';
import 'model/liveness_zkp_concierge_notice.dart';
import 'model/liveness_zkp_concierge_types.dart';

/// Factories for human ZKP concierge notices
abstract final class LivenessZkpConciergeMessages {
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
