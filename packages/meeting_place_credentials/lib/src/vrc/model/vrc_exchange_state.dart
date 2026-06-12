/// Snapshot of the VRC exchange state for a given channel.
///
/// Passed to the VRC protocol handler to determine the correct
/// protocol response without the caller re-threading four separate flags.
class VrcExchangeState {
  /// Creates a [VrcExchangeState] snapshot for a given channel.
  const VrcExchangeState({
    required this.hasVrcExchangeInitiated,
    required this.hasVrcRequestReceived,
    required this.isConnectionInitiator,
    this.hasVrcExchangeCompleted = false,
  });

  /// Whether the local party has initiated a VRC exchange on this channel.
  final bool hasVrcExchangeInitiated;

  /// Whether the local party has already received a VRC issuance request
  /// from the peer on this channel.
  final bool hasVrcRequestReceived;

  /// Whether the local party is the connection initiator for this channel.
  final bool isConnectionInitiator;

  /// Whether the VRC exchange for this channel has already been completed.
  ///
  /// When `true`, `handleReceivedVrc` returns `ignored` immediately. Callers
  /// do not need to guard against duplicate delivery themselves.
  final bool hasVrcExchangeCompleted;
}
