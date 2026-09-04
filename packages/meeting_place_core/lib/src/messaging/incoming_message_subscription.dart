import '../meeting_place_core_sdk.dart' show MeetingPlaceCoreSDK;

/// Specifies what to subscribe to when calling [MeetingPlaceCoreSDK.subscribe].
abstract class IncomingMessageSubscription {
  const IncomingMessageSubscription({required this.ownerDid});

  /// DID of the channel owner. Used to resolve a `DidManager` for the
  /// subscription.
  final String ownerDid;
}

/// Subscribe to incoming DIDComm messages for the owner DID.
class DidCommSubscription extends IncomingMessageSubscription {
  const DidCommSubscription({required super.ownerDid, this.mediatorDid});

  final String? mediatorDid;
}
