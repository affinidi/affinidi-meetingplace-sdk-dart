/// Capability-declaration system for Meeting Place chat transports.
///
/// This file is the single source of truth for which features each transport
/// supports. Adding a new transport requires two changes:
///   1. Add a value to `ChannelTransport` in `package:meeting_place_core`.
///   2. Add a corresponding entry to [TransportCapabilities._registry] below.
///
/// Unknown transports degrade gracefully to
/// [TransportCapabilities._conservative] (text-only) — they never cause a
/// crash or a missing-feature error.
library;

import 'package:meeting_place_core/meeting_place_core.dart';

/// A discrete feature that a chat transport may or may not support.
///
/// Query via [TransportCapabilities.supports] before exposing UI actions
/// that depend on a specific capability.
enum ChatFeature {
  /// Plain text message sending and receiving.
  textMessaging,

  /// Hosted file and image attachments (upload/download via server).
  mediaAttachments,

  /// Voice-note recording and playback as a hosted media attachment.
  voiceMessages,

  /// Emoji/reaction toggling on messages.
  reactions,

  /// Live typing indicator sent to other participants.
  typingIndicators,

  /// Online-presence broadcasts (e.g. "last seen").
  presence,

  /// Read/delivery receipt propagation.
  deliveryReceipts,

  /// In-place editing of already-sent text messages.
  messageEdit,

  /// Redaction / deletion of a sent message for all participants.
  messageDelete,

  /// Visual effect broadcasts (e.g. confetti).
  effects,

  /// Contact-card proposal and acceptance flow.
  contactDetailsUpdate,

  /// Multi-participant group chat rooms.
  groupChat,
}

/// The set of [ChatFeature]s supported by a specific chat transport.
///
/// This class is the authoritative source of truth for transport capabilities.
/// The application layer must query [supports] before offering any UI or
/// action that depends on a given feature:
///
/// ```dart
/// if (chatSDK.capabilities.supports(ChatFeature.messageEdit)) {
///   // show edit option
/// }
/// ```
///
/// **Adding a new transport:**
/// 1. Add a value to `ChannelTransport` in `package:meeting_place_core`.
/// 2. Add a `ChannelTransport.yourTransport: TransportCapabilities({...})`
///    entry to [_registry].
///
/// **Unknown transports** fall back to [_conservative] (text-only) so the app
/// never crashes even when the SDK and app versions are mismatched.
class TransportCapabilities {
  const TransportCapabilities(this.features);

  /// The features supported by this transport.
  final Set<ChatFeature> features;

  /// Returns `true` when this transport supports [feature].
  bool supports(ChatFeature feature) => features.contains(feature);

  // ── Private capability declarations ─────────────────────────────────────

  static const TransportCapabilities _didcomm = TransportCapabilities({
    ChatFeature.textMessaging,
    ChatFeature.reactions,
    ChatFeature.typingIndicators,
    ChatFeature.presence,
    ChatFeature.deliveryReceipts,
    ChatFeature.effects,
    ChatFeature.contactDetailsUpdate,
  });

  static const TransportCapabilities _matrix = TransportCapabilities({
    ChatFeature.textMessaging,
    ChatFeature.mediaAttachments,
    ChatFeature.voiceMessages,
    ChatFeature.reactions,
    ChatFeature.typingIndicators,
    ChatFeature.deliveryReceipts,
    ChatFeature.messageEdit,
    ChatFeature.messageDelete,
    ChatFeature.effects,
    ChatFeature.contactDetailsUpdate,
    ChatFeature.groupChat,
  });

  /// Conservative fallback for transports not yet registered.
  ///
  /// Grants text-only capability so the app stays functional rather than
  /// crashing when it encounters an unrecognised transport value.
  static const TransportCapabilities _conservative = TransportCapabilities({
    ChatFeature.textMessaging,
  });

  static const Map<ChannelTransport, TransportCapabilities> _registry = {
    ChannelTransport.didcomm: _didcomm,
    ChannelTransport.matrix: _matrix,
  };

  /// Returns the [TransportCapabilities] for [transport].
  ///
  /// Falls back to [_conservative] (text-only) when [transport] has no
  /// registered entry, ensuring graceful degradation rather than a crash.
  static TransportCapabilities forTransport(ChannelTransport transport) =>
      _registry[transport] ?? _conservative;
}
