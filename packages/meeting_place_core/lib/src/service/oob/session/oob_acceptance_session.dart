import 'package:ssi/ssi.dart';

import '../../../entity/entity.dart';
import '../../../loggers/meeting_place_core_sdk_logger.dart';
import '../../core_sdk_stream_subscription.dart';
import '../stream/oob_stream.dart';

/// Represents an active OOB acceptance session, created when accepting an OOB
/// offer as the invitee.
class OobAcceptanceSession {
  /// Creates an [OobAcceptanceSession] with the given parameters.
  OobAcceptanceSession({
    required this.channel,
    required this.permanentChannelDidManager,
    required this.permanentChannelDidDocument,
    required this.mediatorDid,
    required CoreSDKStreamSubscription subscription,
    required MeetingPlaceCoreSDKLogger logger,
  }) : stream = OobStream(
         onDispose: () => subscription.dispose(),
         logger: logger,
       );

  /// The channel that has been established as part of the OOB flow.
  final Channel channel;

  /// The DID manager associated with the permanent channel that has been
  /// created as part of the OOB flow. This DID manager can be used for further
  /// interactions with the permanent channel, such as sending messages.
  final DidManager permanentChannelDidManager;

  /// The DID Document associated with the permanent channel that has been
  /// created as part of the OOB flow.
  final DidDocument permanentChannelDidDocument;

  /// The OOB stream that emits events related to the OOB session, such as the
  /// establishment of the permanent channel and acceptance of the OOB offer.
  final OobStream stream;

  /// The DID of the mediator that is used for the connection setup.
  final String mediatorDid;
}
