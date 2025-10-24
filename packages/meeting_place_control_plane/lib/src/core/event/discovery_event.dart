import 'discovery_event_type.dart';

class DiscoveryEvent<T> {
  DiscoveryEvent({
    required this.id,
    required this.type,
    required this.data,
    required this.status,
  });
  final String id;
  final ControlPlaneEventType type;
  final T data;
  final DiscoveryEventStatus status;
}
