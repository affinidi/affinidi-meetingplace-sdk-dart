import 'trust_task_document.dart';
import 'trust_task_receipt.dart';

/// A Trust Task sent and its answer, both signed, exactly as they were on
/// the wire: the request the member's VTA signed, and the answer whose
/// proof checked out.
///
/// Unlike [receipt], it holds the payloads, which can carry details the
/// member disclosed: keep it only in secure storage, and never log it.
class TrustTaskExchange {
  /// Creates a [TrustTaskExchange].
  const TrustTaskExchange({required this.request, required this.answer});

  /// Restores a [TrustTaskExchange] stored with [toJson].
  ///
  /// Throws when a document is malformed.
  factory TrustTaskExchange.fromJson(Map<String, dynamic> json) {
    return TrustTaskExchange(
      request: TrustTaskDocument.fromJson(
        json['request'] as Map<String, dynamic>,
      ),
      answer: TrustTaskDocument.fromJson(
        json['answer'] as Map<String, dynamic>,
      ),
    );
  }

  /// The request, signed.
  final TrustTaskDocument request;

  /// The answer, verified.
  final TrustTaskDocument answer;

  /// What shows the request was signed and answered, without the payloads.
  TrustTaskReceipt get receipt => TrustTaskReceipt.exchange(request, answer);

  /// Serialises for secure storage.
  Map<String, dynamic> toJson() => {
    'request': request.toJson(),
    'answer': answer.toJson(),
  };
}
