import 'package:affinidi_tdk_vdip/affinidi_tdk_vdip.dart';
import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:ssi/ssi.dart';

import '../entity/channel.dart';
import '../loggers/meeting_place_core_sdk_logger.dart';
import '../service/channel/channel_service.dart';
import '../service/connection_manager/connection_manager.dart';
import '../service/mediator/fetch_messages_options.dart';
import '../service/mediator/mediator_service.dart';
import '../vdip/vdip_client.dart';
import 'exceptions/event_handler_exception.dart';

class VdipActivityEventHandler {
  VdipActivityEventHandler({
    required Wallet wallet,
    required MediatorService mediatorService,
    required ChannelService channelService,
    required ConnectionManager connectionManager,
    required MeetingPlaceCoreSDKLogger logger,
    required VdipClient vdipClient,
  }) : _wallet = wallet,
       _mediatorService = mediatorService,
       _channelService = channelService,
       _connectionManager = connectionManager,
       _logger = logger,
       _vdipClient = vdipClient;

  final Wallet _wallet;
  final MediatorService _mediatorService;
  final ChannelService _channelService;
  final ConnectionManager _connectionManager;
  final MeetingPlaceCoreSDKLogger _logger;
  final VdipClient _vdipClient;

  static final String _logKey = 'VdipActivityEventHandler';

  Future<List<Channel>> process(ChannelActivity channelActivity) async {
    final channel = await _channelService.findChannelByDid(channelActivity.did);
    final permanentChannelDid = channel.permanentChannelDid;
    if (permanentChannelDid == null) {
      throw EventHandlerException.missingPermanentChannelDid(
        channelId: channel.id,
      );
    }
    final didManager = await _connectionManager.getDidManagerForDid(
      _wallet,
      permanentChannelDid,
    );

    final messages = await _mediatorService.fetchMessages(
      didManager: didManager,
      mediatorDid: channel.mediatorDid,
      options: FetchMessagesOptions(
        deleteOnRetrieve: false,
        deleteFailedMessages: true,
        filterByMessageTypes: [
          VdipRequestIssuanceMessage.messageType.toString(),
          VdipIssuedCredentialMessage.messageType.toString(),
        ],
      ),
    );

    var processedCount = 0;

    for (final message in messages) {
      _vdipClient.dispatch(message.plainTextMessage);

      for (final processor in _vdipClient.messageProcessors) {
        await processor(message.plainTextMessage);
      }

      processedCount++;

      final messageHash = message.messageHash;
      if (messageHash != null) {
        await _mediatorService.deleteMessages(
          didManager: didManager,
          mediatorDid: channel.mediatorDid,
          messageHashes: [messageHash],
        );
      } else {
        _logger.warning(
          'Skipping VDIP mediator message deletion because message hash is '
          'missing',
          name: _logKey,
        );
      }
    }

    if (processedCount > 0) {
      await _channelService.updateChannelSequence(
        channel,
        sequenceNumber: channel.seqNo + processedCount,
        messageSyncMarker: channel.messageSyncMarker,
      );
    }

    return [channel];
  }
}
