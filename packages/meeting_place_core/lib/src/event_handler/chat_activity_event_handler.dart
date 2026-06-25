import 'package:didcomm/didcomm.dart';
import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';

import '../entity/channel.dart';
import '../entity/connection_offer.dart';
import '../service/matrix/matrix_room_event.dart';
import '../service/matrix/matrix_service.dart';
import '../service/mediator/fetch_messages_options.dart';
import 'base_event_handler.dart';

class ChatActivityEventHandler extends BaseEventHandler<ChannelActivity> {
  ChatActivityEventHandler({
    required super.wallet,
    required super.mediatorService,
    required super.connectionManager,
    required super.connectionOfferRepository,
    required super.channelService,
    required MatrixService matrixService,
    required super.options,
    required super.logger,
  }) : _matrixService = matrixService;

  final MatrixService _matrixService;

  static final String _logKey = 'ChatActivityEventHandler';

  Future<List<Channel>> process(ChannelActivity event) async {
    logger.info(
      'Starting processing event of type ${event.type}',
      name: _logKey,
    );

    try {
      final channel = await channelService.findChannelByDid(event.did);
      switch (channel.transport) {
        case ChannelTransport.didcomm:
          await _syncFromMediator(channel);
        case ChannelTransport.matrix:
          await _syncFromMatrixRoom(channel);
      }

      logger.info(
        'Completed processing event of type ${event.type}',
        name: _logKey,
      );

      return [channel];
    } catch (e, stackTrace) {
      logger.error(
        'Failed to process event of type ${event.type}',
        error: e,
        stackTrace: stackTrace,
        name: _logKey,
      );
      rethrow;
    }
  }

  Future<void> _syncFromMediator(Channel channel) async {
    final didManager = await findDidManager(channel);
    var messageSyncMarker = channel.messageSyncMarker;

    final messages = await mediatorService.fetchMessages(
      didManager: didManager,
      mediatorDid: channel.mediatorDid,
      options: FetchMessagesOptions(
        startFrom: messageSyncMarker,
        batchSize: 100,
        deleteOnRetrieve: false,
        filterByMessageTypes: options.messageTypesForSequenceTracking,
      ),
    );

    int? updatedMessageSeqNumber;
    for (final message in messages) {
      final messageSeqNumber = message.messageSequenceNumber;
      if (messageSeqNumber == null) continue;

      if (messageSeqNumber > channel.seqNo) {
        updatedMessageSeqNumber = messageSeqNumber;
      }

      final createdTime = message.plainTextMessage.createdTime?.toUtc();
      if (createdTime != null &&
          (messageSyncMarker == null ||
              createdTime.compareTo(messageSyncMarker) > 0)) {
        messageSyncMarker = createdTime;
      }
    }

    await channelService.updateChannelSequence(
      channel,
      sequenceNumber: updatedMessageSeqNumber ?? channel.seqNo,
      messageSyncMarker: messageSyncMarker,
    );
  }

  Future<void> _syncFromMatrixRoom(Channel channel) async {
    final didManager = await findDidManager(channel);

    final roomId = await _matrixService.resolveRoomIdForChannel(
      didManager: didManager,
      channel: channel,
    );

    final events = await _matrixService.fetchRoomHistory(
      roomId,
      didManager: didManager,
      sinceEventId: channel.matrixSyncMarker,
    );

    if (events.isEmpty) return;

    final inboundChatCount = events.where(_isInboundNewMessage).length;
    if (inboundChatCount > 0) {
      channel.seqNo += inboundChatCount;
    }

    await channelService.updateMatrixSyncMarker(channel, events.last.id);
  }

  /// True for incoming `m.room.message` events that introduce a new message
  /// to the conversation. Edits arrive with the same `m.room.message` type
  /// but carry an `m.replace` relation and mutate an existing message in
  /// place (see TextMessageHandler / MessageEditHandler), so they must not
  /// contribute to the unread/badge count derived from seqNo.
  bool _isInboundNewMessage(MatrixRoomEvent e) {
    if (e.isFromMe) return false;
    if (e.type != 'm.room.message') return false;
    final relatesTo = e.content['m.relates_to'];
    if (relatesTo is Map && relatesTo['rel_type'] == 'm.replace') return false;
    return true;
  }

  @override
  Future<Channel> processMessage(
    PlainTextMessage message, {
    required ChannelActivity event,
    ConnectionOffer? connection,
    Channel? channel,
  }) async {
    if (channel == null) {
      throw ArgumentError('Channel not found for did ${event.did}');
    }
    return channel;
  }
}
