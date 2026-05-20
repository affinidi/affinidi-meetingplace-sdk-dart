import '../entity/chat_item.dart';
import '../entity/concierge_message.dart';
import 'model/liveness_zkp_concierge_notice.dart';

/// Maps human liveness ZKP concierge notices to chat [ConciergeMessage] rows.
abstract final class LivenessZkpConciergeChatMapper {
  static ConciergeMessage toConciergeMessage(
    LivenessZkpConciergeNotice notice,
  ) {
    return ConciergeMessage(
      chatId: notice.chatId,
      messageId: notice.messageId,
      senderDid: '',
      isFromMe: notice.isFromMe,
      dateCreated: notice.dateCreated,
      status: ChatItemStatus.confirmed,
      data: Map<String, Object?>.from(notice.data),
      conciergeType: ConciergeMessageType.fromJson(notice.conciergeType),
    );
  }
}
