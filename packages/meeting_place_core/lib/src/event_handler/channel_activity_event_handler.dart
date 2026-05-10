import 'package:affinidi_tdk_vdip/affinidi_tdk_vdip.dart';
import 'package:collection/collection.dart';
import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:ssi/ssi.dart';

import '../entity/channel.dart';
import '../loggers/meeting_place_core_sdk_logger.dart';
import '../repository/repository.dart';
import '../service/channel/channel_service.dart';
import '../service/connection_manager/connection_manager.dart';
import '../service/mediator/fetch_messages_options.dart';
import '../service/mediator/mediator_service.dart';
import '../vdip/channel_activity_type.dart';
import '../vdip/vdip_client.dart';
import 'channel_inauguration_event_handler.dart';
import 'chat_activity_event_handler.dart';
import 'control_plane_event_handler_manager_options.dart';
import 'exceptions/event_handler_exception.dart';

class ChannelActivityEventHandler {
  ChannelActivityEventHandler({
    required Wallet wallet,
    required MediatorService mediatorService,
    required ConnectionManager connectionManager,
    required ChannelService channelService,
    required ConnectionOfferRepository connectionOfferRepository,
    required ControlPlaneEventHandlerManagerOptions options,
    required MeetingPlaceCoreSDKLogger logger,
    required VdipClient vdipClient,
  }) : _wallet = wallet,
       _connectionManager = connectionManager,
       _channelService = channelService,
       _connectionOfferRepository = connectionOfferRepository,
       _mediatorService = mediatorService,
       _options = options,
       _logger = logger,
       _vdipClient = vdipClient;

  final Wallet _wallet;
  final MediatorService _mediatorService;
  final ConnectionOfferRepository _connectionOfferRepository;
  final ChannelService _channelService;
  final ConnectionManager _connectionManager;
  final ControlPlaneEventHandlerManagerOptions _options;
  final MeetingPlaceCoreSDKLogger _logger;
  final VdipClient _vdipClient;

  static final String _logKey = 'ChannelActivityEventHandler';

  Future<List<Channel>> process(ChannelActivity channelActivity) async {
    _logger.info(
      'Starting processing event of type ${channelActivity.type}',
      name: _logKey,
    );

    if (channelActivity.type == 'channel-inauguration') {
      _logger.info('Processing channel inauguration event', name: _logKey);
      return ChannelInaugurationEventHandler(
        wallet: _wallet,
        mediatorService: _mediatorService,
        connectionOfferRepository: _connectionOfferRepository,
        channelService: _channelService,
        connectionManager: _connectionManager,
        options: _options,
        logger: _logger,
      ).process(channelActivity);
    }

    if (channelActivity.type == 'chat-activity') {
      _logger.info('Processing chat activity event', name: _logKey);
      return ChatActivityEventHandler(
        wallet: _wallet,
        connectionManager: _connectionManager,
        connectionOfferRepository: _connectionOfferRepository,
        channelService: _channelService,
        mediatorService: _mediatorService,
        options: _options,
        logger: _logger,
      ).process(channelActivity);
    }

    if (channelActivity.type == ChannelActivityType.vdipRequestIssuance ||
        channelActivity.type == ChannelActivityType.vdipIssuedCredentials) {
      _logger.info(
        'Processing VDIP activity event: ${channelActivity.type}',
        name: _logKey,
      );
      return _processVdipActivity(channelActivity);
    }

    _logger.warning(
      'Unsupported channel activity type: ${channelActivity.type}',
      name: _logKey,
    );

    return [];
  }

  bool hasChannelActivityBeenProcessed(
    ChannelActivity channelActivity,
    List<DiscoveryEvent<ChannelActivity>> processedEvents,
  ) {
    return processedEvents.firstWhereOrNull(
          (event) =>
              event.data.did == channelActivity.did &&
              event.data.type == channelActivity.type,
        ) !=
        null;
  }

  Future<List<Channel>> _processVdipActivity(
    ChannelActivity channelActivity,
  ) async {
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
        filterByMessageTypes: [
          VdipRequestIssuanceMessage.messageType.toString(),
          VdipIssuedCredentialMessage.messageType.toString(),
        ],
      ),
    );

    for (final message in messages) {
      _vdipClient.dispatch(message.plainTextMessage);
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

    return [];
  }
}
