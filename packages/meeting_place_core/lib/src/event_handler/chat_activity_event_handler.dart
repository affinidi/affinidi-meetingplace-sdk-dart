import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';

import '../../meeting_place_core.dart';
import 'base_event_handler.dart';
import '../service/mediator/fetch_messages_options.dart';

class ChatActivityEventHandler extends BaseEventHandler {
  ChatActivityEventHandler({
    required super.wallet,
    required super.mediatorService,
    required super.connectionManager,
    required super.connectionOfferRepository,
    required super.channelRepository,
    required super.options,
    required super.logger,
  });

  static final String _logKey = 'ChannelInaugurationEventHandler';

  Future<Channel?> process(ChannelActivity channelActivity) async {
    logger.info(
      'Starting processing event of type ${channelActivity.type}',
      name: _logKey,
    );

    try {
      final channel = await findChannelByDid(channelActivity.did);
      final didManager = await findDidManager(channel);
      var messageSyncMarker = channel.messageSyncMarker;

      // Do not delete from mediator as SDK fetches messages only to update
      // batch count. Another consumer (e.g. ChatSDK) is going to fetch
      // messages again in order to make messsages visible.
      final messages = await mediatorService.fetchMessages(
        didManager: didManager,
        mediatorDid: channel.mediatorDid,
        options: FetchMessagesOptions(
          startFrom: messageSyncMarker,
          batchSize: 100,
          deleteOnRetrieve: false,
          filterByMessageTypes: options.chatActivityMessageTypes,
        ),
      );

      for (final message in messages) {
        final messageSeqNumber = _getMessageSeqNumber(message);
        if (messageSeqNumber == null) continue;

        if (messageSeqNumber > channel.seqNo) {
          channel.seqNo = messageSeqNumber;
        }

        final createdTime = message.plainTextMessage.createdTime?.toUtc();
        if (createdTime != null &&
            (messageSyncMarker == null ||
                createdTime.compareTo(messageSyncMarker) > 0)) {
          messageSyncMarker = createdTime;
        }
      }

      channel.messageSyncMarker = messageSyncMarker;
      await channelRepository.updateChannel(channel);

      logger.info(
        'Completed processing event of type ${channelActivity.type}',
        name: _logKey,
      );

      return channel;
    } catch (e, stackTrace) {
      logger.error(
        'Failed to process event of type ${ControlPlaneEventType.ChannelActivity}',
        error: e,
        stackTrace: stackTrace,
        name: _logKey,
      );
      rethrow;
    }
  }

  int? _getMessageSeqNumber(MediatorMessage message) {
    if (message.seqNo != null) {
      return message.seqNo!;
    }

    final seqNoFromBody = message.plainTextMessage.body?['seq_no'] as int?;
    if (seqNoFromBody != null) {
      return seqNoFromBody;
    }

    return _getSeqNoFromAttachment(message);
  }

  int? _getSeqNoFromAttachment(MediatorMessage message) {
    final attachment = message.plainTextMessage.attachments?.firstWhereOrNull(
      (attachment) => attachment.format == AttachmentFormat.seqNo.value,
    );

    if (attachment?.data?.json == null) return null;

    final json = jsonDecode(attachment!.data!.json!);
    return json['seq_no'] as int?;
  }
}
