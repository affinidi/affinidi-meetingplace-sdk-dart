import 'package:didcomm/didcomm.dart';
import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import '../entity/channel.dart';
import '../entity/connection_offer.dart';
import '../protocol/protocol.dart';
import '../service/mediator/fetch_messages_options.dart';
import 'base_event_handler.dart';

class ChannelInaugurationEventHandler
    extends BaseEventHandler<ChannelActivity> {
  ChannelInaugurationEventHandler({
    required super.wallet,
    required super.connectionOfferRepository,
    required super.channelService,
    required super.connectionManager,
    required super.mediatorService,
    required super.logger,
    required super.options,
  });

  static final String _logKey = 'ChannelInaugurationEventHandler';

  Future<List<Channel>> process(ChannelActivity event) async {
    logger.info(
      'Started processing event of type ${event.type}',
      name: _logKey,
    );

    final channel = await channelService.findChannelByDid(event.did);
    final didManager = await findDidManager(channel);

    return processEvent(
      event: event,
      didManager: didManager,
      mediatorDid: channel.mediatorDid,
      fetchMessageOptions: FetchMessagesOptions(
        filterByMessageTypes: [MeetingPlaceProtocol.channelInauguration.value],
      ),
    );
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

    final channelInaugurationMessage = ChannelInauguration.fromPlainTextMessage(
      message,
    );

    await channelService.markChannelInauguratedFromApprovalRequested(
      channel,
      otherPartyNotificationToken:
          channelInaugurationMessage.body.notificationToken,
    );

    final attachments = channelInaugurationMessage.attachments;
    if (attachments != null && attachments.isNotEmpty) {
      options.onAttachmentsReceived?.call(channel, attachments);
    }

    return channel;
  }
}
