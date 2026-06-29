import 'dart:async';
import 'dart:typed_data';

import 'package:ssi/ssi.dart';

import '../entity/channel.dart';
import '../repository/group_repository.dart';
import '../service/channel/channel_service.dart';
import '../service/mediator/mediator_message.dart';
import '../service/message/message_service.dart';
import '../transport/didcomm_transport.dart';
import '../transport/meeting_place_transport.dart';
import '../transport/transport_event.dart';
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
    required MeetingPlaceTransport channelTransport,
    required MessageService messageService,
    required ChannelService channelService,
    required GroupRepository groupRepository,
    required DIDCommTransport didcomm,
    required Future<DidManager> Function(String did) getDidManager,
  }) : _channelTransport = channelTransport,
       _messageService = messageService,
       _channelService = channelService,
       _groupRepository = groupRepository,
       _didcomm = didcomm,
       _getDidManager = getDidManager;

  final MeetingPlaceTransport _channelTransport;
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

  /// Sends [fileBytes] as a media message on [channel].
  Future<String?> sendMediaMessage(
    Channel channel,
    Uint8List fileBytes, {
    required String contentType,
    String? filename,
    String? caption,
    Map<String, dynamic>? extraContent,
    ChannelNotification? notification,
  }) {
    return _sendChannelMedia(
      channel,
      fileBytes,
      contentType: contentType,
      filename: filename,
      caption: caption,
      extraContent: extraContent,
      notification: notification,
    );
  }

  /// Downloads and decrypts the media identified by [reference] in [channel].
  Future<Uint8List> downloadMedia(
    Channel channel,
    MediaReference reference,
  ) async {
    final didManager = await _getDidManager(_permanentChannelDid(channel));
    return _channelTransport.downloadFile(
      channel: channel,
      fileId: reference.fileId,
      didManager: didManager,
    );
  }

  Future<String?> _sendChannelMedia(
    Channel channel,
    Uint8List fileBytes, {
    required String contentType,
    String? filename,
    String? caption,
    Map<String, dynamic>? extraContent,
    ChannelNotification? notification,
  }) async {
    final didManager = await _getDidManager(_permanentChannelDid(channel));

    final mergedExtra = <String, dynamic>{
      if (caption != null) 'body': caption,
      ...?extraContent,
    };

    final eventId = await _channelTransport.sendFile(
      channel: channel,
      bytes: fileBytes,
      contentType: contentType,
      filename: filename,
      didManager: didManager,
      extraContent: mergedExtra.isEmpty ? null : mergedExtra,
    );

    if (notification != null) {
      unawaited(
        _messageService
            .notifyChannel(notification)
            .catchError((Object _, StackTrace _) {}),
      );
    }

    return eventId;
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

  /// Fires a control-plane channel notification without an accompanying message
  /// body.
  Future<void> notifyChannel(ChannelNotification notification) =>
      _messageService.notifyChannel(notification);

  /// Subscribes to incoming messages for the given [subscription].
  Future<IncomingMessageHandle> subscribe(
    IncomingMessageSubscription subscription,
  ) async {
    switch (subscription) {
      case MatrixRoomSubscription s:
        final channel = await _channelService.findChannelByDid(s.receiverDid);
        final didManager = await _getDidManager(s.receiverDid);
        final participantDids = await _fetchParticipantDids(channel);
        final stream = _channelTransport.subscribe(
          channel: channel,
          didManager: didManager,
          options: s.options,
          participantDids: participantDids,
        );
        final mapped = stream
            .asyncMap((e) async {
              if (_isTimelineEvent(e)) {
                await _advanceMatrixSyncMarker(s.receiverDid, e.id);
              }
              return _toMatrixIncoming(e);
            })
            .where((e) => e != null)
            .cast<MatrixIncomingMessage>();
        return _MatrixIncomingMessageHandle(mapped);
      case DidCommSubscription s:
        final sub = await _didcomm.subscribeToMediator(
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
        final channel = await _channelService.findChannelByDid(q.receiverDid);
        final didManager = await _getDidManager(q.receiverDid);

        final events = await _channelTransport.fetchHistory(
          channel: channel,
          didManager: didManager,
          limit: q.limit,
          sinceEventId: q.sinceEventId,
        );

        if (q.updateChannelSyncMarker && events.isNotEmpty) {
          await _channelService.updateMatrixSyncMarker(channel, events.last.id);
        }

        return events
            .map(_toMatrixIncoming)
            .whereType<MatrixIncomingMessage>()
            .toList();
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

  Future<void> _advanceMatrixSyncMarker(
    String receiverDid,
    String eventId,
  ) async {
    final channel = await _channelService.findChannelByDidOrNull(receiverDid);
    if (channel == null) return;
    await _channelService.updateMatrixSyncMarker(channel, eventId);
  }

  Future<String?> _sendMatrixOutgoing(MatrixOutgoingMessage m) async {
    final channel = await _channelService.findChannelByDid(m.senderDid);
    final didManager = await _getDidManager(m.senderDid);
    final eventId = await _channelTransport.sendEvent(
      channel: channel,
      type: m.type,
      content: m.content,
      didManager: didManager,
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

  bool _isTimelineEvent(TransportEvent event) {
    return event.type != 'm.typing' && event.type != 'm.receipt';
  }

  MatrixIncomingMessage? _toMatrixIncoming(TransportEvent e) {
    final senderDid = e.senderDid;
    if (senderDid == null) return null;
    return MatrixIncomingMessage(
      senderDid: senderDid,
      timestamp: e.timestamp,
      roomId: e.channelId,
      eventId: e.id,
      type: e.type,
      content: e.content,
      isFromMe: e.isFromMe,
      stateKey: e.stateKey,
    );
  }

  Future<List<String>> _fetchParticipantDids(Channel channel) async {
    if (channel.type == ChannelType.group) {
      final group = await _groupRepository.getGroupByOfferLink(
        channel.offerLink,
      );
      if (group == null) return [];
      return group.members.map((m) => m.did).toList();
    }
    final peer = channel.otherPartyPermanentChannelDid;
    if (peer != null) return [peer];
    return [];
  }

  DidCommIncomingMessage _toDidCommIncoming(MediatorMessage m) {
    return DidCommIncomingMessage(
      senderDid: m.fromDid ?? m.plainTextMessage.from ?? '',
      timestamp: m.plainTextMessage.createdTime ?? DateTime.now().toUtc(),
      payload: m.plainTextMessage,
    );
  }

  Future<void> dispose() => _channelTransport.dispose();

  /// Test-only helper that forwards to [MeetingPlaceTransport.awaitChannelReady]
  /// for the channel anchored on [localDid].
  Future<void> waitForRoomEncryptionReady({
    required String localDid,
    required Iterable<String> expectedDids,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final channel = await _channelService.findChannelByDid(localDid);
    final didManager = await _getDidManager(localDid);
    await _channelTransport.awaitChannelReady(
      channel: channel,
      didManager: didManager,
      participantDids: expectedDids,
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
