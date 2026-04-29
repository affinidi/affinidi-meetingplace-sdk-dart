class TrustPolicyDeniedException implements Exception {
  TrustPolicyDeniedException({
    required this.action,
    required this.groupId,
    this.message = 'Trust policy denied the requested action',
  });

  final String action;
  final String groupId;
  final String message;

  @override
  String toString() => '$message (action: $action, groupId: $groupId)';
}
