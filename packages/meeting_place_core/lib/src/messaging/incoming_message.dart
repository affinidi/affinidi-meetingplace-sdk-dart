import 'package:didcomm/didcomm.dart';

import '../meeting_place_core_sdk.dart' show MeetingPlaceCoreSDK;

/// A message received from a transport via [MeetingPlaceCoreSDK.subscribe]
/// or [MeetingPlaceCoreSDK.fetchHistory].
abstract class IncomingMessage {
  /// Creates an [IncomingMessage].
  const IncomingMessage({required this.senderDid, required this.timestamp});

  /// DID of the sender when known.
  final String senderDid;

  /// When the message was sent.
  final DateTime timestamp;
}

/// An [IncomingMessage] received from the DIDComm transport.
class DidCommIncomingMessage extends IncomingMessage {
  /// Creates a [DidCommIncomingMessage].
  const DidCommIncomingMessage({
    required super.senderDid,
    required super.timestamp,
    required this.payload,
  });

  /// The DIDComm plaintext message that was received.
  final PlainTextMessage payload;
}
