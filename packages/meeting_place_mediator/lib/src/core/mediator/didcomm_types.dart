enum DidcommTypes {
  trustPing,
  statusRequest,
  status,
  problemReport,
  chatActivity,
  chatPresence;

  static const Map<DidcommTypes, String> stringValues = {
    DidcommTypes.trustPing: 'https://didcomm.org/trust-ping/2.0/ping',
    DidcommTypes.statusRequest:
        'https://didcomm.org/messagepickup/3.0/status-request',
    DidcommTypes.status: 'https://didcomm.org/messagepickup/3.0/status',
    DidcommTypes.problemReport:
        'https://didcomm.org/report-problem/2.0/problem-report',

    // TODO: handle chat protocol types
    DidcommTypes.chatActivity: 'https://affinidi.io/mpx/chat-sdk/activity',
    DidcommTypes.chatPresence: 'https://affinidi.io/mpx/chat-sdk/presence',
  };

  String get value => stringValues[this]!;

  static List<String> get isEphemeral => [
        DidcommTypes.trustPing.value,
        DidcommTypes.chatActivity.value,
        DidcommTypes.chatPresence.value,
      ];

  static List<String> get isTelemetery => [
        DidcommTypes.status.value,
        DidcommTypes.statusRequest.value,
        DidcommTypes.problemReport.value,
      ];
}
