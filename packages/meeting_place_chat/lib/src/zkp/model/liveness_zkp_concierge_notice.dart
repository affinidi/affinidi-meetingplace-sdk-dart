final class LivenessZkpConciergeNotice {
  const LivenessZkpConciergeNotice({
    required this.chatId,
    required this.messageId,
    required this.dateCreated,
    required this.conciergeType,
    required this.isFromMe,
    this.data = const {},
  });

  final String chatId;
  final String messageId;
  final DateTime dateCreated;

  final String conciergeType;
  final bool isFromMe;
  final Map<String, Object?> data;
}
