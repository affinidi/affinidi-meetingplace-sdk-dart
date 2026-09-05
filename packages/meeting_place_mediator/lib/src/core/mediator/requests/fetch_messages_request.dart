import 'package:didcomm/didcomm.dart';
import 'package:ssi/ssi.dart';

import '../../../meeting_place_mediator_sdk_options.dart';

/// Parameters for `MeetingPlaceMediatorSDK.fetchMessages`.
class FetchMessagesRequest {
  const FetchMessagesRequest({
    required this.didManager,
    this.mediatorDid,
    this.startFrom,
    this.fetchMessagesBatchSize,
    this.deleteOnRetrieve = false,
    this.deleteFailedMessages = false,
    this.expectedMessageWrappingTypes,
  });

  /// The [DidManager] instance used for authentication with the mediator
  /// and contains the identity credentials needed for the session.
  final DidManager didManager;

  /// Optional mediator DID to authenticate against. If not provided, the
  /// SDK instance's default mediator DID will be used.
  final String? mediatorDid;

  /// Only fetch messages received after this timestamp.
  final DateTime? startFrom;

  /// Maximum number of messages to fetch in this call.
  final int? fetchMessagesBatchSize;

  /// Whether messages should be deleted from the mediator upon retrieval.
  final bool deleteOnRetrieve;

  /// Whether messages that failed to decode should be deleted from the
  /// mediator after this fetch.
  final bool deleteFailedMessages;

  /// Message wrapping types to accept. Defaults to the SDK's configured
  /// [MeetingPlaceMediatorSDKOptions.expectedMessageWrappingTypes] when not
  /// provided.
  final List<MessageWrappingType>? expectedMessageWrappingTypes;
}
