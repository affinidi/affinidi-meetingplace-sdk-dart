import 'package:meeting_place_core/meeting_place_core.dart' show Channel;

import 'r_card.dart';

/// Emitted on the SDK `receivedRCardsOnChannel` stream when an
/// R-Card is received via the DIDComm channel-inauguration (OOB) path.
///
/// Carries the originating [channel] so callers can access
/// [Channel.permanentChannelDid] and [Channel.otherPartyPermanentChannelDid]
/// without those fields being duplicated on [RCard].
class ChannelRCardEvent {
  /// Creates a [ChannelRCardEvent] with the originating [channel] and
  /// the parsed [rCard].
  ChannelRCardEvent({required this.channel, required this.rCard});

  /// The channel through which the R-Card arrived.
  final Channel channel;

  /// The parsed and signature-verified R-Card.
  final RCard rCard;
}
