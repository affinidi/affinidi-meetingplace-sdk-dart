import '../../meeting_place_core.dart' show MeetingPlaceCoreSDK;
import '../meeting_place_core_sdk.dart' show MeetingPlaceCoreSDK;
import '../service/matrix/matrix_subscription_options.dart';

/// Specifies what to subscribe to when calling [MeetingPlaceCoreSDK.subscribe].
///
/// The two transports route differently: Matrix subscriptions are scoped to a
/// single room, DIDComm subscriptions deliver every message for the
/// receiving DID across all peers. The discriminator lives in the subclass.
sealed class IncomingMessageSubscription {
  const IncomingMessageSubscription({required this.receiverDid});

  /// DID of the receiver. Used to resolve a `DidManager` for the
  /// subscription.
  final String receiverDid;
}

/// Subscribe to a single Matrix room. The room is resolved from the channel
/// owned by [receiverDid].
class MatrixRoomSubscription extends IncomingMessageSubscription {
  const MatrixRoomSubscription({
    required super.receiverDid,
    this.options = const MatrixSubscriptionOptions(),
  });

  final MatrixSubscriptionOptions options;
}

/// Subscribe to incoming DIDComm messages for the receiver DID.
class DidCommSubscription extends IncomingMessageSubscription {
  const DidCommSubscription({required super.receiverDid, this.mediatorDid});

  final String? mediatorDid;
}
