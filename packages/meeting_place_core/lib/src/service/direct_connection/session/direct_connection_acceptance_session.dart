import 'package:ssi/ssi.dart';

import '../../../entity/entity.dart';
import '../../core_sdk_stream_subscription.dart';
import '../stream/direct_connection_stream_data.dart';

/// Represents an active direct connection acceptance session, created when
/// accepting a direct connection offer as the invitee.
class DirectConnectionAcceptanceSession {
  /// Creates a [DirectConnectionAcceptanceSession] with the given parameters.
  DirectConnectionAcceptanceSession({
    required this.channel,
    required this.permanentChannelDidManager,
    required this.permanentChannelDidDocument,
    required this.mediatorDid,
    required this.stream,
  });

  /// The channel that has been established as part of the direct connection.
  final Channel channel;

  /// The DID manager associated with the permanent channel that has been
  /// created as part of the direct connection. This DID manager can be used
  /// for further interactions with the permanent channel, such as sending
  /// messages.
  final DidManager permanentChannelDidManager;

  /// The DID Document associated with the permanent channel that has been
  /// created as part of the direct connection.
  final DidDocument permanentChannelDidDocument;

  /// The direct connection stream that emits events related to the session,
  /// such as the establishment of the permanent channel and acceptance of the
  /// offer.
  final CoreSDKStreamSubscription<DirectConnectionStreamData, void> stream;

  /// The DID of the mediator that is used for the connection setup.
  final String mediatorDid;
}
