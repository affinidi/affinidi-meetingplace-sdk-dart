import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import '../entity/channel.dart';
import '../protocol/protocol.dart';
import 'base_event_handler.dart';
import 'exceptions/empty_message_list_exception.dart';

class ChannelInaugurationEventHandler extends BaseEventHandler {
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

  Future<Channel?> process(ChannelActivity channelActivity) async {
    logger.info(
      'Started processing event of type ${channelActivity.type}',
      name: _logKey,
    );

    try {
      final channel = await channelService.findChannelByDid(
        channelActivity.did,
      );
      final didManager = await findDidManager(channel);

      final messages = await fetchMessagesFromMediatorWithRetry(
        didManager: didManager,
        mediatorDid: channel.mediatorDid,
        messageType: MeetingPlaceProtocol.channelInauguration,
      );

      logger.info('Found ${messages.length} messages', name: _logKey);
      for (final message in messages) {
        logger.info(
          '''Processing message with id ${message.plainTextMessage.id} and 
          type ${message.plainTextMessage.type} for
          DID ${channelActivity.did}''',
          name: _logKey,
        );

        final channelInaugurationMessage =
            ChannelInauguration.fromPlainTextMessage(message.plainTextMessage);

        await channelService.markChannelInauguratedFromApprovalRequested(
          channel,
          otherPartyNotificationToken:
              channelInaugurationMessage.body.notificationToken,
        );

        final attachments = channelInaugurationMessage.attachments;
        if (attachments != null && attachments.isNotEmpty) {
          options.onAttachmentsReceived?.call(channel, attachments);
        }
      }

      logger.info(
        'Completed processing event of type ${channelActivity.type}',
        name: _logKey,
      );
      return channel;
    } on EmptyMessageListException {
      logger.warning(
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
