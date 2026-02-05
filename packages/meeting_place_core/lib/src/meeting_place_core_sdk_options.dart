import 'package:didcomm/didcomm.dart';
import 'package:ssi/ssi.dart';

import 'entity/channel.dart';

/// Callback to build attachments for outgoing connection messages
/// during the channel inauguration process.
///
/// Called by the SDK when processing connection events that require
/// sending attachments to the other party.
typedef OnBuildAttachmentsCallback =
    Future<List<Attachment>?> Function(Channel channel);

/// Callback invoked when attachments are received from the other party
/// during connection establishment.
///
/// The app should process these attachments when this callback is invoked.
typedef OnAttachmentsReceivedCallback =
    void Function(Channel channel, List<Attachment> attachments);

class MeetingPlaceCoreSDKOptions {
  const MeetingPlaceCoreSDKOptions({
    this.secondsBeforeExpiryReauthenticate = 60,
    this.debounceControlPlaneEvents = const Duration(milliseconds: 200),
    this.didResolverAddress,
    this.maxRetries = 3,
    this.maxRetriesDelay = const Duration(milliseconds: 2000),
    this.eventHandlerMessageFetchMaxRetries = 3,
    this.eventHandlerMessageFetchMaxRetriesDelay = const Duration(
      milliseconds: 3000,
    ),
    this.connectTimeout = const Duration(milliseconds: 30000),
    this.receiveTimeout = const Duration(milliseconds: 30000),
    this.signatureScheme = SignatureScheme.ecdsa_p256_sha256,
    this.expectedMessageWrappingTypes = const [
      MessageWrappingType.authcryptSignPlaintext,
    ],
    this.onBuildAttachments,
    this.onAttachmentsReceived,
  });

  /// Number of seconds before the access token is refreshed to ensure
  /// continued access to the mediator instance.
  final int secondsBeforeExpiryReauthenticate;

  /// Number of miliseconds to wait before processing discovery events.
  /// This debounce mechanism is used to let multiple events settle and process
  /// them at once.
  final Duration debounceControlPlaneEvents;

  /// Specifies the custom address utilized by the DID resolver service.
  final String? didResolverAddress;

  /// The number of retry attempts for a request when a network issue occurs.
  /// If a request fails due to a network error, it will be retried up to this
  /// number of times before ultimately failing.
  final int maxRetries;

  /// The maximum delay between retry attempts when a network issue occurs.
  /// This value sets the upper bound for the delay between retries.
  final Duration maxRetriesDelay;

  /// The number of retry attempts for a request when fetching messages
  /// from the mediator within control plane event handlers.
  ///
  /// If a fetch request returns no messages, it will be retried up to this
  /// number of times before giving up.
  ///
  /// This retry mechanism helps prevent race conditions between receiving
  /// signals from the control plane API and the availability of corresponding
  /// messages from the mediator.
  ///
  /// Without retries, messages triggered by control plane events might not be
  /// immediately accessible, leading to missed or delayed processing.
  final int eventHandlerMessageFetchMaxRetries;

  /// The maximum delay between retry attempts when fetching messages from
  /// the mediator within control plane event handlers.
  ///
  /// This value sets the upper bound for the delay between retries.
  final Duration eventHandlerMessageFetchMaxRetriesDelay;

  /// Specifies the maximum time (in milliseconds) the SDK will wait while
  /// establishing a connection to the server. If the connection cannot be
  /// established within this time, the request will be aborted and a timeout
  /// error will be thrown.
  final Duration connectTimeout;

  /// Defines the maximum duration (in milliseconds) the SDK will wait to
  /// receive a response after a connection has been successfully established.
  /// If no data is received within this time frame, the request will be
  /// aborted and a timeout error will be triggered.
  final Duration receiveTimeout;

  /// The signature scheme to be used for signing messages.
  final SignatureScheme signatureScheme;

  /// Expected message wrapping types for unpacking DIDComm messages.
  ///
  /// Defaults to [MessageWrappingType.authcryptSignPlaintext]
  ///
  /// Set to both [MessageWrappingType.authcryptPlaintext] and
  /// [MessageWrappingType.authcryptSignPlaintext] if using multiple protocols
  /// (e.g., chat + VDIP) that use different message signing configurations.
  final List<MessageWrappingType> expectedMessageWrappingTypes;

  /// Callback to build attachments for outgoing connection messages
  /// during the channel inauguration process.
  ///
  /// When provided, this callback is invoked by event handlers when they need
  /// to send attachments to the other party (e.g., during OfferFinalised).
  ///
  /// The callback receives the [Channel] being processed and should return
  /// a list of [Attachment] objects to include in the outgoing message.
  final OnBuildAttachmentsCallback? onBuildAttachments;

  /// Callback invoked when attachments are received from the other party
  /// during connection establishment.
  ///
  /// When provided, this callback is invoked by event handlers after they
  /// receive and process incoming attachments from connection messages.
  final OnAttachmentsReceivedCallback? onAttachmentsReceived;
}
