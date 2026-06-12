import 'package:collection/collection.dart';
import 'package:meeting_place_credentials/meeting_place_credentials.dart';

import '../entity/chat_attachment_conversion.dart';
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
          LivenessZkpAttachmentParser.matchesRequestFormat(
            attachment.toDIDComm(),
          ) ||
          LivenessZkpAttachmentParser.matchesProofFormat(
            attachment.toDIDComm(),
          ),
    );
  }

  static bool isHumanZkpConcierge(ChatItem item) {
    if (item is! ConciergeMessage) return false;
    return LivenessZkpConciergeTypes.isHumanZkpType(item.conciergeType.value);
  }

  static ({bool hasRequest, bool hasProof}) _attachmentKinds(Message message) {
    if (message.value.isNotEmpty || message.attachments.isEmpty) {
      return (hasRequest: false, hasProof: false);
    }

    return (
      hasRequest:
          LivenessZkpAttachmentParser.tryParseRequestIn(
            message.attachments.map((a) => a.toDIDComm()),
          ) !=
          null,
      hasProof:
          LivenessZkpAttachmentParser.tryParseProofIn(
            message.attachments.map((a) => a.toDIDComm()),
          ) !=
          null,
    );
  }

  static List<LivenessZkpConciergeNotice> deriveNoticesFromMessage(
    Message item, {
    required String contactName,
    ({bool hasRequest, bool hasProof})? attachmentKinds,
  }) {
    final out = <LivenessZkpConciergeNotice>[];
    if (item.value.isNotEmpty || item.attachments.isEmpty) return out;

    final kinds = attachmentKinds ?? _attachmentKinds(item);

    if (kinds.hasRequest && !item.isFromMe) {
      out.add(
        LivenessZkpConciergeMessages.humanZkpRequest(
          chatId: item.chatId,
          messageId: LivenessZkpConciergeIds.requestReceived(item.messageId),
          dateCreated: item.dateCreated,
          contactName: contactName,
        ),
      );
    }

    if (kinds.hasProof && item.isFromMe) {
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
    ({bool hasRequest, bool hasProof})? attachmentKinds,
  }) {
    return deriveNoticesFromMessage(
      item,
      contactName: contactName,
      attachmentKinds: attachmentKinds,
    ).map(LivenessZkpConciergeChatMapper.toConciergeMessage).toList();
  }

  /// TODO(pagination): Replace full history scan with one of:
  /// - incremential updates when a zkp message is upserted
  /// - persisted zkp flow state or a target repository for latest zkp
  ///  attachments per chat
  /// Rebuilds the chat item list with derived human ZKP concierge messages.
  static List<ChatItem> appendDerivedHumanZkpConciergeMessages(
    List<ChatItem> existing, {
    required String contactName,
  }) {
    ({Message message, bool hasRequest, bool hasProof})? latestIncomingRequest;
    ({Message message, bool hasRequest, bool hasProof})? latestMyProof;
    Message? latestTheirProof;

    for (final item in existing) {
      if (item is! Message || !messageHasZkpAttachments(item)) continue;

      final kinds = _attachmentKinds(item);

      if (kinds.hasRequest && !item.isFromMe) {
        if (latestIncomingRequest == null ||
            item.dateCreated.isAfter(
              latestIncomingRequest.message.dateCreated,
            )) {
          latestIncomingRequest = (
            message: item,
            hasRequest: kinds.hasRequest,
            hasProof: kinds.hasProof,
          );
        }
      }
      if (kinds.hasProof && item.isFromMe) {
        if (latestMyProof == null ||
            item.dateCreated.isAfter(latestMyProof.message.dateCreated)) {
          latestMyProof = (
            message: item,
            hasRequest: kinds.hasRequest,
            hasProof: kinds.hasProof,
          );
        }
      }
      if (kinds.hasProof && !item.isFromMe) {
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
          !latestMyProof.message.dateCreated.isBefore(
            latestIncomingRequest.message.dateCreated,
          );
      if (!fulfilledByMyProof) {
        derived.addAll(
          deriveConciergeMessagesFromMessage(
            latestIncomingRequest.message,
            contactName: contactName,
            attachmentKinds: (
              hasRequest: latestIncomingRequest.hasRequest,
              hasProof: latestIncomingRequest.hasProof,
            ),
          ),
        );
      }
    }
    if (latestMyProof != null) {
      derived.addAll(
        deriveConciergeMessagesFromMessage(
          latestMyProof.message,
          contactName: contactName,
          attachmentKinds: (
            hasRequest: latestMyProof.hasRequest,
            hasProof: latestMyProof.hasProof,
          ),
        ),
      );
    }
    if (latestTheirProof != null) {
      derived.add(
        LivenessZkpConciergeChatMapper.toConciergeMessage(
          LivenessZkpConciergeMessages.humanZkpProofReceived(
            chatId: latestTheirProof.chatId,
            messageId: LivenessZkpConciergeIds.proofReceived(
              latestTheirProof.messageId,
            ),
            dateCreated: latestTheirProof.dateCreated,
            contactName: contactName,
          ),
        ),
      );
    }
    final latestRequestNoticeId = latestIncomingRequest == null
        ? null
        : LivenessZkpConciergeIds.requestReceived(
            latestIncomingRequest.message.messageId,
          );

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

    final withoutHumanZkp = existing.where(
      (item) => !isHumanZkpConcierge(item),
    );

    return [
      ...withoutHumanZkp,
      ...pausedNotices,
      ...derived,
    ].sortedBy((item) => item.dateCreated).reversed.toList();
  }
}
