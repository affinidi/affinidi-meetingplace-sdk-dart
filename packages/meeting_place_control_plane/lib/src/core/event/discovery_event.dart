import 'discovery_event_type.dart';

/// A notification event received from the control plane, wrapping its
/// typed payload [data] together with the event's [type] and [status].
class ControlPlaneEvent<T> {
  /// Creates a new instance of [ControlPlaneEvent].
  ControlPlaneEvent({
    required this.id,
    required this.type,
    required this.data,
    required this.status,
  });

  /// The unique identifier of this event.
  final String id;

  /// The kind of event this is.
  final ControlPlaneEventType type;

  /// The event's typed payload.
  final T data;

  /// The processing status of this event.
  final ControlPlaneEventStatus status;
}
