import 'package:didcomm/didcomm.dart' show Attachment;

import '../entity/channel.dart';
import '../meeting_place_core_sdk_options.dart';

export '../meeting_place_core_sdk_options.dart' show OnBuildAttachmentsCallback;

class ControlPlaneEventHandlerManagerOptions {
  const ControlPlaneEventHandlerManagerOptions({
    this.maxRetries = 3,
    this.maxRetriesDelay = const Duration(milliseconds: 5000),
    this.messageTypesForSequenceTracking = const [],
    this.onBuildAttachments,
    this.onAttachmentsReceived,
    this.agentDid,
  });

  /// The number of retry attempts for a request when a network issue occurs.
  /// If a request fails due to a network error, it will be retried up to this
  /// number of times before ultimately failing.
  final int maxRetries;

  /// The maximum delay between retry attempts when a network issue occurs.
  /// This value sets the upper bound for the delay between retries.
  final Duration maxRetriesDelay;

  /// The list of message types that are considered relevant for chat activity.
  /// When processing channel activity events, only messages with these types
  /// will be considered for updating the channel's message synchronization
  /// marker and sequence number.
  final List<String> messageTypesForSequenceTracking;

  /// Callback to build attachments (e.g., R-Card credentials) for outgoing
  /// connection messages during the channel inauguration process.
  final OnBuildAttachmentsCallback? onBuildAttachments;

  /// Sink invoked when attachments are received from the other party
  /// during connection establishment. Feeds into the SDK's
  /// channelAttachments broadcast stream.
  final void Function(Channel, List<Attachment>)? onAttachmentsReceived;

  /// The raw agent DID (e.g. `did:key:…`) that the personal agent subscribes
  /// with. When set, [OfferFinalisedEventHandler] routes the
  /// `agent-channel-inauguration` message to this DID rather than to the
  /// agent's channel-specific `did:web`.
  final String? agentDid;
}
