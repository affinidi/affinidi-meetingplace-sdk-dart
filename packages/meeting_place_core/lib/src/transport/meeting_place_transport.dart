import 'dart:typed_data';

import 'package:ssi/ssi.dart';

import '../entity/channel.dart';
import 'transport_event.dart';
import 'transport_subscription_options.dart';

/// Transport-agnostic abstraction over channel-based messaging backends.
///
/// Each concrete transport implements this interface so that
/// MeetingPlaceCoreSDK and its services have zero dependency on any
/// specific messaging protocol.
///
/// DIDComm-specific operations without a channel-level analogue
/// (e.g. `queueMessage`, `deleteMessages`) remain on DIDCommTransport
/// and are accessed directly where needed.
abstract interface class MeetingPlaceTransport {
  // ---------------------------------------------------------------------------
  // Auth / identity
  // ---------------------------------------------------------------------------

  /// Authenticates [didManager]'s identity with the transport backend.
  ///
  /// Performs a JWT exchange via the control plane and logs
  /// in. For DIDComm this is typically a no-op.
  Future<void> authenticate(DidManager didManager);

  // ---------------------------------------------------------------------------
  // Channel lifecycle
  // ---------------------------------------------------------------------------

  /// Creates or initialises the underlying channel resource for [channel].
  ///
  /// Creates an encrypted room and invites [participantDids].
  /// For DIDComm this is a no-op (the mediator access list is managed
  /// separately).
  Future<void> setupChannel({
    required Channel channel,
    required DidManager didManager,
    List<String> participantDids = const [],
  });

  /// Joins [channel]'s underlying resource when it already exists.
  Future<void> joinChannel({
    required Channel channel,
    required DidManager didManager,
  });

  /// Leaves [channel]'s underlying resource.
  Future<void> leaveChannel({
    required Channel channel,
    required DidManager didManager,
  });

  /// Invites [participantDid] to [channel].
  Future<void> inviteToChannel({
    required Channel channel,
    required String participantDid,
    required DidManager didManager,
  });

  /// Removes [participantDid] from [channel].
  Future<void> removeFromChannel({
    required Channel channel,
    required String participantDid,
    required DidManager didManager,
  });

  // ---------------------------------------------------------------------------
  // Messaging
  // ---------------------------------------------------------------------------

  /// Returns a live stream of events for [channel].
  ///
  /// [participantDids] is used by implementations that cannot natively map
  /// transport user IDs back to DIDs — the implementation
  /// resolves [TransportEvent.senderDid] using these candidates before emitting
  /// each event.
  Stream<TransportEvent> subscribe({
    required Channel channel,
    required DidManager didManager,
    TransportSubscriptionOptions? options,
    List<String> participantDids = const [],
  });

  /// Returns historical events for [channel].
  ///
  /// [since] is a cursor; if null, the most recent events are returned.
  Future<List<TransportEvent>> fetchHistory({
    required Channel channel,
    required DidManager didManager,
    int? limit,
    String? since,
  });

  /// Returns the id of the most recent event in [channel], or null if
  /// the channel has no events or the transport does not track event ids.
  Future<String?> getLastEventId({
    required Channel channel,
    required DidManager didManager,
  });

  /// Sends a typed event to [channel].
  ///
  /// Returns the transport id, or null for transports / event types that do
  /// not produce one.
  Future<String?> sendEvent({
    required Channel channel,
    required String type,
    required Map<String, dynamic> content,
    required DidManager didManager,
  });

  // ---------------------------------------------------------------------------
  // Media
  // ---------------------------------------------------------------------------

  /// Uploads [bytes] to [channel] and returns the transport-assigned file id,
  /// or null when the implementation defers returning an id.
  ///
  /// Throws [UnimplementedError] for transports that do not yet support media.
  Future<String?> sendFile({
    required Channel channel,
    required Uint8List bytes,
    required String contentType,
    String? filename,
    required DidManager didManager,
    Map<String, dynamic>? extraContent,
  });

  /// Downloads and decrypts the file identified by [fileId] in [channel].
  ///
  /// Throws [UnimplementedError] for transports that do not yet support media.
  Future<Uint8List> downloadFile({
    required Channel channel,
    required String fileId,
    required DidManager didManager,
  });

  // ---------------------------------------------------------------------------
  // Misc
  // ---------------------------------------------------------------------------

  /// The backend server identifier.
  /// Null if the transport does not have a single server identity.
  String? get serverId;

  /// Returns true if [event] represents a new inbound message that should
  /// increment the channel unread/sequence counter.
  ///
  /// Edits, receipts, and other non-content events should return false.
  bool isNewInboundMessage(TransportEvent event);

  /// Disposes any long-lived resources owned by this transport.
  Future<void> dispose();
}
