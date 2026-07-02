import 'package:didcomm/didcomm.dart';

import '../meeting_place_core_sdk.dart' show MeetingPlaceCoreSDK;

/// A message received from a transport via [MeetingPlaceCoreSDK.subscribe]
/// or [MeetingPlaceCoreSDK.fetchHistory].
abstract class IncomingMessage {
  const IncomingMessage({required this.senderDid, required this.timestamp});

  /// DID of the sender when known.
  final String senderDid;

  final DateTime timestamp;
}

/// An [IncomingMessage] received from the DIDComm transport.
class DidCommIncomingMessage extends IncomingMessage {
  const DidCommIncomingMessage({
    required super.senderDid,
    required super.timestamp,
    required this.payload,
  });

  final PlainTextMessage payload;
}
