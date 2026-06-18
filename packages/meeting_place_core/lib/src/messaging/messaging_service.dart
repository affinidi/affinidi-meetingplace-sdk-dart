import 'dart:async';
import 'dart:typed_data';

import 'package:ssi/ssi.dart';

import '../entity/channel.dart';
import '../repository/group_repository.dart';
import '../service/channel/channel_service.dart';
import '../service/matrix/matrix_media_exception.dart';
import '../service/matrix/matrix_room_event.dart';
import '../service/matrix/matrix_service.dart';
import '../service/matrix/matrix_user_id_binding.dart';
import '../service/mediator/mediator_message.dart';
import '../service/message/message_service.dart';
import '../transport/didcomm_transport.dart';
import 'history_query.dart';
import 'incoming_message.dart';
import 'incoming_message_handle.dart';
import 'incoming_message_subscription.dart';
import 'media_reference.dart';
import 'outgoing_message.dart';

/// Transport-agnostic facade for the send / subscribe / fetchHistory message
/// operations. Dispatches each call to the appropriate transport (Matrix or
/// DIDComm). Exception wrapping is handled by the caller (typically the
/// meeting place core SDK).
class MessagingService {
  MessagingService({
    required MatrixService matrixService,
    required MessageService messageService,
    required ChannelService channelService,
    required GroupRepository groupRepository,
    required DIDCommTransport didcomm,
    required Future<DidManager> Function(String did) getDidManager,
  }) : _matrixService = matrixService,
       _messageService = messageService,
       _channelService = channelService,
       _groupRepository = groupRepository,
       _didcomm = didcomm,
       _getDidManager = getDidManager;

  final MatrixService _matrixService;
  final MessageService _messageService;
  final ChannelService _channelService;
  final GroupRepository _groupRepository;
  final DIDCommTransport _didcomm;
  final Future<DidManager> Function(String did) _getDidManager;

  /// Sends [message] through its transport (Matrix or DIDComm).
  ///
  /// Returns the Matrix event id for [MatrixOutgoingMessage] (or `null` for
  /// matrix events that don't produce one, such as `m.read`, `m.typing`,
  /// `m.room.redaction`). Always returns `null` for [DidCommOutgoingMessage].
  Future<String?> sendMessage(OutgoingMessage message) async {
    return switch (message) {
      MatrixOutgoingMessage m => await _sendMatrixOutgoing(m),
      DidCommOutgoingMessage m =>
        await _didcomm
            .sendMessage(
              m.payload,
              senderDid: m.senderDid,
              recipientDid: m.recipientDid,
              mediatorDid: m.mediatorDid,
              notifyChannelType: m.notifyChannelType,
              ephemeral: m.ephemeral,
              forwardExpiryInSeconds: m.forwardExpiryInSeconds,
            )
            .then((_) => null),
      _ => throw ArgumentError(
        'Unsupported OutgoingMessage subtype: ${message.runtimeType}',
      ),
    };
  }

  /// Sends [fileBytes] as a media message on [channel]. The transport
  /// (Matrix or DIDComm) is selected from [Channel.transport]; encryption,
  /// upload, and event posting are delegated to the underlying transport.
  ///
  /// For Matrix channels: returns the server-assigned event id (or `null`
  /// when the matrix client did not produce one). For DIDComm channels:
  /// currently throws [UnimplementedError]; inline-attachment support is
  /// deferred to a follow-up.
  ///
  /// Throws [MatrixMediaException.tooLarge] when [fileBytes] exceeds the
  /// transport's maximum allowed size.
  Future<String?> sendMediaMessage(
    Channel channel,
    Uint8List fileBytes, {
    required String contentType,
    String? filename,
    String? caption,
    Map<String, dynamic>? extraContent,
  }) {
    switch (channel.transport) {
      case ChannelTransport.matrix:
        return _sendMatrixMedia(
          channel,
          fileBytes,
          contentType: contentType,
          filename: filename,
          caption: caption,
          extraContent: extraContent,
        );
      case ChannelTransport.didcomm:
        // TODO(media-upload): inline-attachment DIDComm path; enforce
        // mediator/message-size cap before packaging bytes.
        throw UnimplementedError('DIDComm media upload is not implemented yet');
    }
  }

  /// Downloads and decrypts the media identified by [reference] in [channel].
  /// Symmetric with [sendMediaMessage]; the [MediaReference] subtype must
  /// match [Channel.transport] (e.g. [MatrixEventMediaReference] for Matrix).
  Future<Uint8List> downloadMedia(
    Channel channel,
    MediaReference reference, {
    bool localOnly = false,
  }) async {
    switch ((channel.transport, reference)) {
      case (ChannelTransport.matrix, MatrixEventMediaReference ref):
        final didManager = await _getDidManager(_permanentChannelDid(channel));
        final roomId = await _matrixService.resolveRoomIdForChannel(
          didManager: didManager,
          channel: channel,
        );
        return _matrixService.downloadFileForEvent(
          roomId,
          ref.eventId,
          didManager: didManager,
          localOnly: localOnly,
        );
      case (ChannelTransport.didcomm, _):
        throw UnimplementedError(
          'DIDComm media download is not implemented yet',
        );
    }
  }

  Future<String?> _sendMatrixMedia(
    Channel channel,
    Uint8List fileBytes, {
    required String contentType,
    String? filename,
    String? caption,
    Map<String, dynamic>? extraContent,
  }) async {
    final didManager = await _getDidManager(_permanentChannelDid(channel));

    final maxSize = await _matrixService.getMediaConfig(didManager: didManager);
    if (maxSize != null && fileBytes.length > maxSize) {
      throw MatrixMediaException.tooLarge(maxBytes: maxSize);
    }

    final roomId = await _matrixService.resolveRoomIdForChannel(
      didManager: didManager,
      channel: channel,
    );

    final mergedExtra = <String, dynamic>{
      if (caption != null) 'body': caption,
      ...?extraContent,
    };

    return _matrixService.sendFileEvent(
      roomId,
      bytes: fileBytes,
      contentType: contentType,
      filename: filename,
      didManager: didManager,
      extraContent: mergedExtra.isEmpty ? null : mergedExtra,
    );
  }

  String _permanentChannelDid(Channel channel) {
    final did = channel.permanentChannelDid;
    if (did == null) {
      throw StateError(
        'Channel ${channel.id} has no permanentChannelDid; '
        'media operations require an inaugurated channel',
      );
    }
    return did;
  }

  /// Subscribes to incoming messages for the given [subscription].
  ///
  /// For [MatrixRoomSubscription], yields events from a single room. Each
  /// delivered event advances [Channel.matrixSyncMarker] for the subscribing
  /// DID's channel before the event is yielded, so a restart resumes from the
  /// last event seen.
  /// For [DidCommSubscription], yields DIDComm messages for the receiver DID
  /// across all peers.
  ///
  /// The returned [IncomingMessageHandle] owns the underlying transport
  /// subscription. Callers MUST call [IncomingMessageHandle.dispose] when they
  /// are done to release the connection — for DIDComm this closes the
  /// long-lived mediator subscription, which otherwise leaks and keeps
  /// consuming messages from the server.
  Future<IncomingMessageHandle> subscribe(
    IncomingMessageSubscription subscription,
  ) async {
    switch (subscription) {
      case MatrixRoomSubscription s:
        final roomId = await _resolveRoomIdForDid(s.receiverDid);
        final stream = _matrixService.subscribeToRoom(
          roomId,
          didManager: await _getDidManager(s.receiverDid),
          options: s.options,
        );
        // Capture a cutoff so that pre-join events the matrix client loads
        // into the timeline (via room history visibility) are not delivered
        // through the live subscription. Catch-up of post-marker events is
        // the job of fetchHistory.
        final cutoff = DateTime.now().toUtc();
        final mapped = stream
            .where((e) => !_isTimelineEvent(e) || !e.timestamp.isBefore(cutoff))
            .asyncMap((e) async {
              if (_isTimelineEvent(e)) {
                await _advanceMatrixSyncMarker(s.receiverDid, e.id);
              }
              return _toMatrixIncoming(e, s.receiverDid);
            });
        // Matrix uses an async generator: cancelling the consumer's
        // listen() terminates the generator and its room listeners. No
        // separate teardown is required, so dispose is a no-op.
        return _MatrixIncomingMessageHandle(mapped);
      case DidCommSubscription s:
        final sub = await _didcomm.subscribe(
          s.receiverDid,
          mediatorDid: s.mediatorDid,
        );
        return _DidCommIncomingMessageHandle(
          stream: sub.stream.map(_toDidCommIncoming),
          onDispose: sub.dispose,
        );
    }
  }

  /// Fetches historical messages for the given [query].
  Future<List<IncomingMessage>> fetchHistory(HistoryQuery query) async {
    switch (query) {
      case MatrixRoomHistoryQuery q:
        final channel = await _channelService.findChannelByDidOrNull(
          q.receiverDid,
        );
        // Prefer the caller-supplied cursor (chat session's own anchor,
        // typically the latest persisted message's transport id) over the
        // channel-level sync marker. The marker is owned by the push
        // pipeline (ChatActivityEventHandler) which uses it for badge-count
        // bookkeeping and must not be consumed here.
        final sinceEventId = q.sinceEventId ?? channel?.matrixSyncMarker;
        final roomId = await _resolveRoomIdForDid(q.receiverDid);
        final events = await _matrixService.fetchRoomHistory(
          roomId,
          didManager: await _getDidManager(q.receiverDid),
          limit: q.limit,
          sinceEventId: sinceEventId,
        );
        return Future.wait(
          events.map((e) => _toMatrixIncoming(e, q.receiverDid)),
        );
      case DidCommHistoryQuery q:
        final messages = await _didcomm.fetchMessages(
          did: q.receiverDid,
          mediatorDid: q.mediatorDid,
          deleteOnRetrieve: q.deleteOnRetrieve,
          deleteFailedMessages: q.deleteFailedMessages,
        );
        return messages
            .take(q.limit)
            .map<IncomingMessage>(_toDidCommIncoming)
            .toList();
    }
  }

  Future<String> _resolveRoomIdForDid(String did) async {
    final channel = await _channelService.findChannelByDidOrNull(did);
    if (channel == null) {
      throw StateError('No channel found for DID $did');
    }
    final didManager = await _getDidManager(did);
    return _matrixService.resolveRoomIdForChannel(
      didManager: didManager,
      channel: channel,
    );
  }

  Future<void> _advanceMatrixSyncMarker(
    String receiverDid,
    String eventId,
  ) async {
    final channel = await _channelService.findChannelByDidOrNull(receiverDid);
    if (channel == null) return;
    await _channelService.updateMatrixSyncMarker(channel, eventId);
  }

  Future<String?> _sendMatrixOutgoing(MatrixOutgoingMessage m) async {
    final roomId = await _resolveRoomIdForDid(m.senderDid);
    final eventId = await _matrixService.sendRoomEvent(
      roomId,
      m.type,
      m.content,
      didManager: await _getDidManager(m.senderDid),
    );

    final notification = m.notification;
    if (notification != null) {
      unawaited(
        _messageService
            .notifyChannel(notification)
            .catchError((Object _, StackTrace _) {}),
      );
    }

    return eventId;
  }

  /// Whether [event] represents a real timeline event whose id should be used
  /// as a sync cursor. Ephemeral events (typing, receipts) carry synthetic or
  /// non-cursor ids and must not advance [Channel.matrixSyncMarker].
  bool _isTimelineEvent(MatrixRoomEvent event) {
    return event.type != 'm.typing' && event.type != 'm.receipt';
  }

  Future<MatrixIncomingMessage> _toMatrixIncoming(
    MatrixRoomEvent e,
    String receiverDid,
  ) async {
    final resolved =
        e.senderDid ??
        await _resolveSenderDid(
          receiverDid: receiverDid,
          matrixUserId: e.userId,
        );
    return MatrixIncomingMessage(
      senderDid: resolved ?? e.userId,
      timestamp: e.timestamp,
      roomId: e.roomId,
      eventId: e.id,
      type: e.type,
      content: e.content,
      isFromMe: e.isFromMe,
      stateKey: e.stateKey,
    );
  }

  /// Reverses [deriveMatrixUserId] for [matrixUserId] by hashing every DID
  /// that could legitimately appear in [receiverDid]'s room (self + peer for
  /// individual channels, self + group members for group channels) and
  /// returning the one whose derived user id matches. Returns `null` when no
  /// candidate matches.
  Future<String?> _resolveSenderDid({
    required String receiverDid,
    required String matrixUserId,
  }) async {
    final channel = await _channelService.findChannelByDidOrNull(receiverDid);
    if (channel == null) return null;

    final serverName = _matrixService.homeserver.host;
    bool matches(String did) =>
        deriveMatrixUserId(did, serverName) == matrixUserId;

    if (matches(receiverDid)) return receiverDid;

    if (channel.type == ChannelType.group) {
      final group = await _groupRepository.getGroupByOfferLink(
        channel.offerLink,
      );
      if (group == null) return null;
      for (final m in group.members) {
        if (matches(m.did)) return m.did;
      }
      return null;
    }

    final peer = channel.otherPartyPermanentChannelDid;
    if (peer != null && matches(peer)) return peer;
    return null;
  }

  DidCommIncomingMessage _toDidCommIncoming(MediatorMessage m) {
    return DidCommIncomingMessage(
      senderDid: m.fromDid ?? m.plainTextMessage.from ?? '',
      timestamp: m.plainTextMessage.createdTime ?? DateTime.now().toUtc(),
      payload: m.plainTextMessage,
    );
  }

  /// Disposes the underlying matrix service. Safe to call multiple times.
  Future<void> dispose() => _matrixService.dispose();

  /// Test-only helper that forwards to
  /// [MatrixService.waitForRoomEncryptionReady] for the channel anchored on
  /// [localDid]. See that method for why callers (test fixtures) need it.
  Future<void> waitForRoomEncryptionReady({
    required String localDid,
    required Iterable<String> expectedDids,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final didManager = await _getDidManager(localDid);
    final roomId = await _resolveRoomIdForDid(localDid);
    await _matrixService.waitForRoomEncryptionReady(
      roomId: roomId,
      didManager: didManager,
      expectedDids: expectedDids,
      timeout: timeout,
    );
  }
}

class _MatrixIncomingMessageHandle implements IncomingMessageHandle {
  _MatrixIncomingMessageHandle(this.stream);

  @override
  final Stream<IncomingMessage> stream;

  @override
  Future<void> dispose() async {}
}

class _DidCommIncomingMessageHandle implements IncomingMessageHandle {
  _DidCommIncomingMessageHandle({
    required this.stream,
    required this.onDispose,
  });

  @override
  final Stream<IncomingMessage> stream;

  final Future<void> Function() onDispose;

  @override
  Future<void> dispose() => onDispose();
}
