import 'package:collection/collection.dart';
import 'package:meeting_place_relationship/meeting_place_relationship.dart';

import '../entity/chat_item.dart';
import '../entity/concierge_message.dart';
import '../entity/message.dart';
import 'liveness_zkp_concierge_chat_mapper.dart';
import 'liveness_zkp_concierge_messages.dart';
import 'model/liveness_zkp_concierge_ids.dart';
import 'model/liveness_zkp_concierge_notice.dart';
import 'model/liveness_zkp_concierge_types.dart';

/// Derives human liveness ZKP concierge rows from chat [Message] items.
abstract final class LivenessZkpConciergeDeriver {
  static bool messageHasZkpAttachments(Message message) {
    if (message.value.isNotEmpty || message.attachments.isEmpty) return false;

    return message.attachments.any(
      (attachment) =>
          LivenessZkpAttachmentParser.matchesRequestFormat(attachment) ||
          LivenessZkpAttachmentParser.matchesProofFormat(attachment),
    );
  }

  static bool isHumanZkpConcierge(ChatItem item) {
    if (item is! ConciergeMessage) return false;
    return LivenessZkpConciergeTypes.isHumanZkpType(item.conciergeType.value);
  }

  static List<LivenessZkpConciergeNotice> deriveNoticesFromMessage(
    Message item, {
    required String contactName,
  }) {
    final out = <LivenessZkpConciergeNotice>[];
    if (item.value.isNotEmpty || item.attachments.isEmpty) return out;

    final hasRequest =
        LivenessZkpAttachmentParser.tryParseRequestIn(item.attachments) != null;
    final hasProof =
        LivenessZkpAttachmentParser.tryParseProofIn(item.attachments) != null;

    if (hasRequest && !item.isFromMe) {
      out.add(
        LivenessZkpConciergeMessages.humanZkpRequest(
          chatId: item.chatId,
          messageId: LivenessZkpConciergeIds.requestReceived(item.messageId),
          dateCreated: item.dateCreated,
          contactName: contactName,
        ),
      );
    }

    if (hasProof && item.isFromMe) {
      out.add(
        LivenessZkpConciergeMessages.humanZkpProofShared(
          chatId: item.chatId,
          messageId: LivenessZkpConciergeIds.proofShared(item.messageId),
          dateCreated: item.dateCreated,
        ),
      );
    }

    return out;
  }

  static List<ConciergeMessage> deriveConciergeMessagesFromMessage(
    Message item, {
    required String contactName,
  }) {
    return deriveNoticesFromMessage(
      item,
      contactName: contactName,
    ).map(LivenessZkpConciergeChatMapper.toConciergeMessage).toList();
  }

  /// Rebuilds the chat item list with derived human ZKP concierge messages.
  static List<ChatItem> appendDerivedHumanZkpConciergeMessages(
    List<ChatItem> existing, {
    required String contactName,
  }) {
    Message? latestIncomingRequest;
    Message? latestMyProof;
    Message? latestTheirProof;

    for (final item in existing) {
      if (item is! Message || !messageHasZkpAttachments(item)) continue;

      final hasRequest =
          LivenessZkpAttachmentParser.tryParseRequestIn(item.attachments) !=
          null;
      final hasProof =
          LivenessZkpAttachmentParser.tryParseProofIn(item.attachments) != null;

      if (hasRequest && !item.isFromMe) {
        if (latestIncomingRequest == null ||
            item.dateCreated.isAfter(latestIncomingRequest.dateCreated)) {
          latestIncomingRequest = item;
        }
      }
      if (hasProof && item.isFromMe) {
        if (latestMyProof == null ||
            item.dateCreated.isAfter(latestMyProof.dateCreated)) {
          latestMyProof = item;
        }
      }
      if (hasProof && !item.isFromMe) {
        if (latestTheirProof == null ||
            item.dateCreated.isAfter(latestTheirProof.dateCreated)) {
          latestTheirProof = item;
        }
      }
    }

    final derived = <ConciergeMessage>[];

    if (latestIncomingRequest != null) {
      final fulfilledByMyProof =
          latestMyProof != null &&
          !latestMyProof.dateCreated.isBefore(
            latestIncomingRequest.dateCreated,
          );
      if (!fulfilledByMyProof) {
        derived.addAll(
          deriveConciergeMessagesFromMessage(
            latestIncomingRequest,
            contactName: contactName,
          ),
        );
      }
    }
    if (latestMyProof != null) {
      derived.addAll(
        deriveConciergeMessagesFromMessage(
          latestMyProof,
          contactName: contactName,
        ),
      );
    }
    final latestRequestNoticeId = latestIncomingRequest == null
        ? null
        : LivenessZkpConciergeIds.requestReceived(
            latestIncomingRequest.messageId,
          );

    final latestIncomingProofNoticeId = latestTheirProof == null
        ? null
        : LivenessZkpConciergeIds.proofReceived(latestTheirProof.messageId);

    final pausedNotices = existing.whereType<ConciergeMessage>().where(
      (notice) =>
          notice.conciergeType.value ==
              LivenessZkpConciergeTypes.humanZkpPaused &&
          (latestRequestNoticeId == null ||
              notice.messageId ==
                  LivenessZkpConciergeIds.paused(
                    forRequestNoticeMessageId: latestRequestNoticeId,
                  )),
    );

    final verifiedProofNotices = existing.whereType<ConciergeMessage>().where(
      (notice) =>
          notice.conciergeType.value ==
              LivenessZkpConciergeTypes.humanZkpProofReceived &&
          latestIncomingProofNoticeId != null &&
          notice.messageId == latestIncomingProofNoticeId,
    );

    final withoutHumanZkp = existing.where(
      (item) => !isHumanZkpConcierge(item),
    );

    return [
      ...withoutHumanZkp,
      ...pausedNotices,
      ...verifiedProofNotices,
      ...derived,
    ].sortedBy((item) => item.dateCreated).reversed.toList();
  }
}
