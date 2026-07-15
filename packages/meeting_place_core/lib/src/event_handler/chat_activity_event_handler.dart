import 'package:didcomm/didcomm.dart';
import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';

import '../entity/channel.dart';
import '../entity/connection_offer.dart';
import '../service/mediator/fetch_messages_options.dart';
import '../transport/meeting_place_transport.dart';
import 'base_event_handler.dart';

class ChatActivityEventHandler extends BaseEventHandler<ChannelActivity> {
  ChatActivityEventHandler({
    required super.wallet,
    required super.mediatorService,
    required super.connectionManager,
    required super.connectionOfferRepository,
    required super.channelService,
    required MeetingPlaceTransport channelTransport,
    required super.options,
    required super.logger,
  }) : _channelTransport = channelTransport;

  final MeetingPlaceTransport _channelTransport;

  static final String _logKey = 'ChatActivityEventHandler';

  Future<List<Channel>> process(ChannelActivity event) async {
    logger.info(
      'Starting processing event of type ${event.type}',
      name: _logKey,
    );

    try {
      final channel = await channelService.findChannelByDid(event.did);
      if (channel.transport == ChannelTransport.didcomm) {
        await _syncFromMediator(channel);
      } else {
        await _syncFromChannelTransport(channel);
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
    var messageSyncMarker = channel.messageSyncMarker != null
        ? DateTime.parse(channel.messageSyncMarker!)
        : null;

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
      messageSyncMarker: messageSyncMarker?.toUtc().toIso8601String(),
    );
  }

  Future<void> _syncFromChannelTransport(Channel channel) async {
    final didManager = await findDidManager(channel);

    final events = await _channelTransport.fetchHistory(
      channel: channel,
      didManager: didManager,
      since: channel.messageSyncMarker,
    );

    if (events.isEmpty) return;

    final inboundChatCount = events
        .where(_channelTransport.isNewInboundMessage)
        .length;
    if (inboundChatCount > 0) {
      channel.seqNo += inboundChatCount;
    }

    // Advance the sync marker to the newest event by timestamp, not by list
    // position. `fetchHistory` is not guaranteed to return events in
    // chronological order (the matrix timeline is newest-first), so
    // `events.last` is the oldest fetched event. Anchoring the marker there
    // leaves newer events "unseen", so the next sync re-fetches and re-counts
    // them — inflating `seqNo` (and the unread badge) by the size of the fetch
    // window on every subsequent activity. Picking the max-timestamp event
    // advances the marker past everything just counted.
    final newestEvent = events.reduce(
      (a, b) => b.timestamp.isAfter(a.timestamp) ? b : a,
    );
    await channelService.updateMessageSyncMarker(channel, newestEvent.id);
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
