import 'dart:async';
import 'dart:typed_data';

import 'package:ssi/ssi.dart';

import '../entity/channel.dart';
import '../service/mediator/mediator_message.dart';
import '../service/message/message_service.dart';
import '../transport/didcomm_transport.dart';
import '../transport/meeting_place_transport.dart';
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
    required DIDCommTransport didcomm,
    required Future<DidManager> Function(String did) getDidManager,
  }) : _channelTransport = channelTransport,
       _messageService = messageService,
       _didcomm = didcomm,
       _getDidManager = getDidManager;

  final MeetingPlaceTransport _channelTransport;
  final MessageService _messageService;
  final DIDCommTransport _didcomm;
  final Future<DidManager> Function(String did) _getDidManager;

  /// Sends [message] via DIDComm. Returns `null` for [DidCommOutgoingMessage].
  ///
  /// Subclasses may override to support additional transports.
  Future<String?> sendMessage(OutgoingMessage message) async {
    return switch (message) {
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
      _ => throw UnsupportedError(
        'Unsupported OutgoingMessage type: ${message.runtimeType}',
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
    if (channel.transport == ChannelTransport.didcomm) {
      throw UnimplementedError('sendMediaMessage is not supported for DIDComm');
    }
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
    if (channel.transport == ChannelTransport.didcomm) {
      throw UnimplementedError('downloadMedia is not supported for DIDComm');
    }
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

  /// Subscribes to incoming messages for [subscription].
  ///
  /// Only [DidCommSubscription] is handled by this base implementation.
  /// Subclasses may override to support additional transports.
  Future<IncomingMessageHandle> subscribe(
    IncomingMessageSubscription subscription,
  ) async {
    switch (subscription) {
      case DidCommSubscription s:
        final sub = await _didcomm.subscribeToMediator(
          s.receiverDid,
          mediatorDid: s.mediatorDid,
        );
        return _DidCommIncomingMessageHandle(
          stream: sub.stream.map(_toDidCommIncoming),
          onDispose: sub.dispose,
        );
      default:
        throw UnsupportedError(
          'Unsupported subscription type: ${subscription.runtimeType}',
        );
    }
  }

  /// Fetches historical messages for [query].
  ///
  /// Only [DidCommHistoryQuery] is handled by this base implementation.
  /// Subclasses may override to support additional transports.
  Future<List<IncomingMessage>> fetchHistory(HistoryQuery query) async {
    switch (query) {
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
      default:
        throw UnsupportedError(
          'Unsupported history query type: ${query.runtimeType}',
        );
    }
  }

  DidCommIncomingMessage _toDidCommIncoming(MediatorMessage m) {
    return DidCommIncomingMessage(
      senderDid: m.fromDid ?? m.plainTextMessage.from ?? '',
      timestamp: m.plainTextMessage.createdTime ?? DateTime.now().toUtc(),
      payload: m.plainTextMessage,
    );
  }

  Future<void> dispose() => _channelTransport.dispose();
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
