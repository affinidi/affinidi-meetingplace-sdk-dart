import 'package:didcomm/didcomm.dart';

/// A message received from a transport via [MeetingPlaceCoreSDK.subscribe]
/// or [MeetingPlaceCoreSDK.fetchHistory].
///
/// Mirrors [OutgoingMessage]: one transport-specific subtype per transport.
/// CoreSDK does not produce chat-domain subtypes (e.g. a "typing event"
/// class) — consumers in the chat package dispatch on [MatrixIncomingMessage.type]
/// and wrap into their own domain values.
abstract class IncomingMessage {
  const IncomingMessage({required this.senderDid, required this.timestamp});

  /// DID of the sender when known. For incoming Matrix events where only the
  /// Matrix user ID is available, this may be the user ID instead.
  final String senderDid;

  final DateTime timestamp;
}

/// An [IncomingMessage] received from the Matrix transport.
class MatrixIncomingMessage extends IncomingMessage {
  const MatrixIncomingMessage({
    required super.senderDid,
    required super.timestamp,
    required this.roomId,
    required this.eventId,
    required this.type,
    required this.content,
    this.isFromMe = false,
  });

  final String roomId;
  final String eventId;
  final String type;
  final Map<String, dynamic> content;
  final bool isFromMe;
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
