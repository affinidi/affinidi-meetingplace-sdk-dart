/// Resolved MatrixRTC call session identity for the next join attempt.
class CallSessionPreparation {
  const CallSessionPreparation({required this.callId, required this.isRejoin});

  final String callId;
  final bool isRejoin;
}
