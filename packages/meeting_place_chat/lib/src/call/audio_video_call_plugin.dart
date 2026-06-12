import 'incoming_call_event.dart';

/// Interface for a calling plugin (audio and/or video).
///
/// Implement this to provide calling capability for a given contact.
/// The implementation is responsible for resolving all transport-specific
/// details (e.g. Matrix room ID, LiveKit token) from the `contactId`.
///
/// Register the implementation via `audioVideoCallPluginProvider` in
/// `main.dart`. If no plugin is registered (provider returns `null`),
/// the UI hides the call button.
///
/// Returning `false` from [isSupported] signals that the plugin is installed
/// but unavailable in the current context (e.g. protocol mismatch, missing
/// config, or unsupported OS).
abstract interface class AudioVideoCallPlugin {
  /// Whether this plugin can operate in the current context.
  ///
  /// Returns `false` when the active identity is not connected via a
  /// protocol that supports real-time calls (e.g. DIDComm-only mode,
  /// where Matrix is not used) or when required configuration is absent.
  bool get isSupported;

  /// Stream of incoming call events from remote parties.
  ///
  /// The app shell listens to this stream and presents the incoming call
  /// banner when an event arrives.
  Stream<IncomingCallEvent> get incomingCalls;

  /// Starts an outbound call for the contact identified by [contactId].
  ///
  /// The implementation resolves all transport details internally. The
  /// caller only needs the stable app-level contact identity.
  Future<void> startCall({required String contactId});

  /// Accepts an incoming call identified by [callId].
  ///
  /// [callId] must match the value from the corresponding [IncomingCallEvent].
  Future<void> acceptCall({required String callId});

  /// Declines an incoming call identified by [callId] before answering.
  ///
  /// Sends a rejection signal to the caller.
  Future<void> declineCall({required String callId});

  /// Ends an active call identified by [callId].
  ///
  /// Use to hang up during an active call. For pre-answer rejections,
  /// use [declineCall] instead.
  Future<void> endCall({required String callId});
}
