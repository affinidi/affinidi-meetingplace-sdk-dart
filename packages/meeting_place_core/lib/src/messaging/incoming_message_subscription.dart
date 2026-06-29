import '../meeting_place_core_sdk.dart' show MeetingPlaceCoreSDK;

/// Specifies what to subscribe to when calling [MeetingPlaceCoreSDK.subscribe].
abstract class IncomingMessageSubscription {
  const IncomingMessageSubscription({required this.receiverDid});

  /// DID of the receiver. Used to resolve a `DidManager` for the subscription.
  final String receiverDid;
}

/// Subscribe to incoming DIDComm messages for the receiver DID.
class DidCommSubscription extends IncomingMessageSubscription {
  const DidCommSubscription({required super.receiverDid, this.mediatorDid});

  final String? mediatorDid;
}
