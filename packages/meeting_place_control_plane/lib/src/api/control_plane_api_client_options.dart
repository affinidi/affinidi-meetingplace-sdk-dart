/// [ControlPlaneApiClientOptions] is a class that defines options when initialising
/// the [DiscoveryApiClient].
class ControlPlaneApiClientOptions {
  /// Create an instance of the [ControlPlaneApiClientOptions] class.
  ControlPlaneApiClientOptions({
    required this.controlPlaneDid,
    this.connectTimeout = 30000,
    this.receiveTimeout = 30000,
    this.maxRetries = 3,
    this.maxRetriesDelay = 2000,
  });
  final String controlPlaneDid;
  final int connectTimeout;
  final int receiveTimeout;
  final int maxRetries;
  final int maxRetriesDelay;

  Map<String, dynamic> toJson() {
    return {
      'controlPlaneDid': controlPlaneDid,
      'connectTimeout': connectTimeout,
      'receiveTimeout': receiveTimeout,
      'maxRetries': maxRetries,
      'maxRetriesDelay': maxRetriesDelay,
    };
  }
}
