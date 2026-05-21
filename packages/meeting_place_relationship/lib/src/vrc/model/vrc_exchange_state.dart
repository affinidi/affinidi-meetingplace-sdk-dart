/// Snapshot of the VRC exchange state for a given channel.
///
/// Passed to the VRC protocol handler to determine the correct
/// protocol response without the caller re-threading four separate flags.
class VrcExchangeState {
  const VrcExchangeState({
    required this.hasVrcExchangeInitiated,
    required this.hasVrcRequestReceived,
    required this.isConnectionInitiator,
  });

  /// Whether the local party has initiated a VRC exchange on this channel.
  final bool hasVrcExchangeInitiated;

  /// Whether the local party has already received a VRC issuance request
  /// from the peer on this channel.
  final bool hasVrcRequestReceived;

  /// Whether the local party is the connection initiator for this channel.
  final bool isConnectionInitiator;
}
