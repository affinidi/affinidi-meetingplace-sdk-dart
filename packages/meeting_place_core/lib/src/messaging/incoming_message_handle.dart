import 'dart:async';

import '../../meeting_place_core.dart' show MeetingPlaceCoreSDK;
import '../meeting_place_core_sdk.dart' show MeetingPlaceCoreSDK;
import 'incoming_message.dart';

/// Handle returned by [MeetingPlaceCoreSDK.subscribe] that exposes the live
/// [stream] of [IncomingMessage]s for the subscription and a [dispose] hook
/// that tears down the underlying transport connection.
///
/// Callers MUST call [dispose] when they are done with the subscription,
/// otherwise the underlying mediator (for DIDComm) or Matrix room listener
/// will remain active and keep consuming messages from the server.
abstract class IncomingMessageHandle {
  /// The live stream of incoming messages for this subscription.
  Stream<IncomingMessage> get stream;

  /// Tear down the underlying transport subscription. Idempotent.
  Future<void> dispose();
}
