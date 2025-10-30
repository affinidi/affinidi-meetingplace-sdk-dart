import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import '../entity/channel.dart';
import '../protocol/meeting_place_protocol.dart';
import '../utils/string.dart';
import 'base_event_handler.dart';
import 'exceptions/empty_message_list_exception.dart';

class ChannelInaugurationEventHandler extends BaseEventHandler {
  ChannelInaugurationEventHandler({
    required super.wallet,
    required super.connectionOfferRepository,
    required super.channelRepository,
    required super.connectionManager,
    required super.mediatorService,
    required super.logger,
    required super.options,
  });

  static final String _logKey = 'ChannelInaugurationEventHandler';

  Future<Channel?> process(ChannelActivity channelActivity) async {
    logger.info(
      'Started processing event of type ${channelActivity.type}',
      name: _logKey,
    );

    try {
      final channel = await findChannelByDid(channelActivity.did);
      final didManager = await findDidManager(channel);

      final messages = await fetchMessagesFromMediatorWithRetry(
        didManager: didManager,
        mediatorDid: channel.mediatorDid,
        messageType: MeetingPlaceProtocol.channelInauguration,
      );

      logger.info('Found ${messages.length} in inbox', name: _logKey);
      for (final message in messages) {
        final plainTextMessage = message.plainTextMessage;

        logger.info(
          'Peeked message ${plainTextMessage.type.toString().topAndTail(charCountTop: 8, charCountTail: 20)} from ${channel.permanentChannelDid!.topAndTail()}',
          name: _logKey,
        );

        channel.otherPartyNotificationToken =
            plainTextMessage.body!['notificationToken'] as String;
        channel.status = ChannelStatus.inaugaurated;

        await channelRepository.updateChannel(channel);
      }

      logger.info(
        'Completed processing event of type ${channelActivity.type}',
        name: _logKey,
      );
      return channel;
    } on EmptyMessageListException {
      logger.error(
        'No messages found to process for event of type ${ControlPlaneEventType.ChannelActivity}',
        name: _logKey,
      );
      return null;
    } catch (e, stackTrace) {
      logger.error(
        '''Failed to process event of type ${ControlPlaneEventType.ChannelActivity} -> ${e.toString()}''',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
