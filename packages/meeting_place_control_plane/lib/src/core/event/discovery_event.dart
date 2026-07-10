import 'discovery_event_type.dart';

class ControlPlaneEvent<T> {
  ControlPlaneEvent({
    required this.id,
    required this.type,
    required this.data,
    required this.status,
  });
  final String id;
  final ControlPlaneEventType type;
  final T data;
  final ControlPlaneEventStatus status;
}
