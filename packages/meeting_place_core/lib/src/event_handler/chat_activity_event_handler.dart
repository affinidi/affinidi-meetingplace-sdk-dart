import 'package:didcomm/didcomm.dart';
import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';

import '../entity/channel.dart';
import '../entity/connection_offer.dart';
import '../service/mediator/fetch_messages_options.dart';
import 'base_event_handler.dart';

class ChatActivityEventHandler extends BaseEventHandler<ChannelActivity> {
  ChatActivityEventHandler({
    required super.wallet,
    required super.mediatorService,
    required super.connectionManager,
    required super.connectionOfferRepository,
    required super.channelService,
    required super.options,
    required super.logger,
  });

  static final String _logKey = 'ChannelInaugurationEventHandler';

  Future<List<Channel>> process(ChannelActivity event) async {
    logger.info(
      'Starting processing event of type ${event.type}',
      name: _logKey,
    );

    try {
      final channel = await channelService.findChannelByDid(event.did);
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
