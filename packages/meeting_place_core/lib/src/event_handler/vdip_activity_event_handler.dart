import 'package:affinidi_tdk_vdip/affinidi_tdk_vdip.dart';
import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:ssi/ssi.dart';

import '../entity/channel.dart';
import '../loggers/meeting_place_core_sdk_logger.dart';
import '../service/channel/channel_service.dart';
import '../service/connection_manager/connection_manager.dart';
import '../service/mediator/fetch_messages_options.dart';
import '../service/mediator/mediator_service.dart';
import 'exceptions/event_handler_exception.dart';

class VdipActivityEventHandler {
  VdipActivityEventHandler({
    required Wallet wallet,
    required MediatorService mediatorService,
    required ChannelService channelService,
    required ConnectionManager connectionManager,
    required MeetingPlaceCoreSDKLogger logger,
  }) : _wallet = wallet,
       _mediatorService = mediatorService,
       _channelService = channelService,
       _connectionManager = connectionManager,
       _logger = logger;

  final Wallet _wallet;
  final MediatorService _mediatorService;
  final ChannelService _channelService;
  final ConnectionManager _connectionManager;
  final MeetingPlaceCoreSDKLogger _logger;

  static final String _logKey = 'VdipActivityEventHandler';

  /// Handles a VDIP channel-activity push by syncing the channel's sequence
  /// state from the mediator so consumers can derive a badge count.
  ///
  /// This handler does NOT dispatch, persist, or delete the VDIP messages.
  /// Like `ChatActivityEventHandler`, a channel-activity handler only advances
  /// [Channel.seqNo] and [Channel.messageSyncMarker]; the messages stay on the
  /// mediator and are delivered (and surfaced) the next time the chat session
  /// connects with `fetchMessagesOnConnect`. Dispatching from this push path
  /// as well caused the same VDIP issued-credential to be surfaced twice (once
  /// here and once from the chat session), producing duplicate R-Cards.
  Future<List<Channel>> process(ChannelActivity channelActivity) async {
    _logger.info(
      'Starting processing event of type ${channelActivity.type}',
      name: _logKey,
    );

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

    var messageSyncMarker = channel.messageSyncMarker;

    final messages = await _mediatorService.fetchMessages(
      didManager: didManager,
      mediatorDid: channel.mediatorDid,
      options: FetchMessagesOptions(
        startFrom: messageSyncMarker,
        deleteOnRetrieve: false,
        filterByMessageTypes: [
          VdipRequestIssuanceMessage.messageType.toString(),
          VdipIssuedCredentialMessage.messageType.toString(),
        ],
      ),
    );

    var processedCount = 0;
    for (final message in messages) {
      processedCount++;

      final createdTime = message.plainTextMessage.createdTime?.toUtc();
      if (createdTime != null &&
          (messageSyncMarker == null ||
              createdTime.compareTo(messageSyncMarker) > 0)) {
        messageSyncMarker = createdTime;
      }
    }

    if (processedCount > 0) {
      await _channelService.updateChannelSequence(
        channel,
        sequenceNumber: channel.seqNo + processedCount,
        messageSyncMarker: messageSyncMarker,
      );
    }

    _logger.info(
      'Completed processing event of type ${channelActivity.type}',
      name: _logKey,
    );

    return [channel];
  }
}
