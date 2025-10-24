import '../../core/event/discovery_event.dart';

/// Model that represents the output data returned from a successful execution
/// of [GetPendingNotificationsCommandOutput] operation.
class GetPendingNotificationsCommandOutput {
  /// Creates a new instance of [GetPendingNotificationsCommandOutput].
  GetPendingNotificationsCommandOutput({required this.events});
  final List<DiscoveryEvent> events;
}
