import '../meeting_place_core_sdk.dart' show MeetingPlaceCoreSDK;

/// Specifies what to subscribe to when calling [MeetingPlaceCoreSDK.subscribe].
abstract class IncomingMessageSubscription {
  /// Creates an [IncomingMessageSubscription].
  const IncomingMessageSubscription({required this.ownerDid});

  /// DID of the channel owner. Used to resolve a `DidManager` for the
  /// subscription.
  final String ownerDid;
}

/// Subscribe to incoming DIDComm messages for the owner DID.
class DidCommSubscription extends IncomingMessageSubscription {
  /// Creates a [DidCommSubscription].
  const DidCommSubscription({required super.ownerDid, this.mediatorDid});

  /// The mediator's DID to subscribe through. If not provided, the SDK's
  /// configured mediator DID is used.
  final String? mediatorDid;
}
