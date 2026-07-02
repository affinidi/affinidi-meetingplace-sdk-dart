class MatrixReadReceiptEvent {
  const MatrixReadReceiptEvent({
    required this.roomId,
    required this.eventId,
    required this.userId,
    required this.timestamp,
  });

  final String roomId;
  final String eventId;
  final String userId;
  final DateTime timestamp;
}
