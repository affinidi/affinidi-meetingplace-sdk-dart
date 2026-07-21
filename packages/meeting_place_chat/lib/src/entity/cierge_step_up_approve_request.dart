import 'dart:convert';

/// Parsed payload for a `cierge/stepUpApproveRequest` message relayed through
/// chat when the VTA's DIDComm push to the approver is unavailable.
///
/// Use [fromMessageText] to attempt parsing; returns `null`
/// for non-matching input.
class CiergeStepUpApproveRequest {
  const CiergeStepUpApproveRequest({required this.approveRequest});

  static const String messageType = 'cierge/stepUpApproveRequest';

  static const String conciergeTypeName = 'stepUpApproveRequest';

  final Map<String, dynamic> approveRequest;

  Map<String, dynamic> get payload =>
      approveRequest['payload'] as Map<String, dynamic>? ?? approveRequest;

  String? get sessionId => payload['sessionId'] as String?;
  String? get challenge => payload['challenge'] as String?;
  String? get subject => payload['subject'] as String?;
  String? get reason => payload['reason'] as String?;

  static CiergeStepUpApproveRequest? fromMessageText(String text) {
    try {
      final decoded = jsonDecode(text);
      if (decoded is! Map<String, dynamic>) return null;
      if (decoded['type'] != messageType) return null;
      final approveRequest = decoded['approveRequest'] as Map<String, dynamic>?;
      if (approveRequest == null) return null;
      return CiergeStepUpApproveRequest(approveRequest: approveRequest);
    } catch (_) {
      return null;
    }
  }
}
