import 'package:meeting_place_core/meeting_place_core.dart';

/// Subscribe to a single Matrix room. The room is resolved from the channel
/// owned by [ownerDid].
class MatrixRoomSubscription extends IncomingMessageSubscription {
  const MatrixRoomSubscription({
    required super.ownerDid,
    this.options = const TransportSubscriptionOptions(),
  });

  final TransportSubscriptionOptions options;
}
