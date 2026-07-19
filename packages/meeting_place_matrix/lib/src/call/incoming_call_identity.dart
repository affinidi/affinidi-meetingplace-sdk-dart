/// Resolved identity for an incoming call: transport callId (or room fallback)
/// and the resolved Matrix room ID.
class IncomingCallIdentity {
  IncomingCallIdentity({required this.callId, required this.roomId});

  final String callId;
  final String roomId;
}
