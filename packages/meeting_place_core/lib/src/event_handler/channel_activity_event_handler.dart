import 'package:collection/collection.dart';
import 'package:meeting_place_control_plane/meeting_place_control_plane.dart'
    hide ChannelActivityType;
import 'package:ssi/ssi.dart';

import '../entity/channel.dart';
import '../loggers/meeting_place_core_sdk_logger.dart';
import '../repository/repository.dart';
import '../service/channel/channel_service.dart';
import '../service/connection_manager/connection_manager.dart';
import '../service/matrix/matrix_service.dart';
import '../service/mediator/mediator_service.dart';
import '../vdip/channel_activity_type.dart';
import '../vdip/vdip_client.dart';
import 'channel_inauguration_event_handler.dart';
import 'chat_activity_event_handler.dart';
import 'control_plane_event_handler_manager_options.dart';
import 'vdip_activity_event_handler.dart';

class ChannelActivityEventHandler {
  ChannelActivityEventHandler({
    required Wallet wallet,
    required MediatorService mediatorService,
    required ConnectionManager connectionManager,
    required ChannelService channelService,
    required ConnectionOfferRepository connectionOfferRepository,
    required MatrixService matrixService,
    required ControlPlaneEventHandlerManagerOptions options,
    required MeetingPlaceCoreSDKLogger logger,
    required VdipClient vdipClient,
  }) : _wallet = wallet,
       _connectionManager = connectionManager,
       _channelService = channelService,
       _connectionOfferRepository = connectionOfferRepository,
       _mediatorService = mediatorService,
       _matrixService = matrixService,
       _options = options,
       _logger = logger,
       _vdipClient = vdipClient;

  final Wallet _wallet;
  final MediatorService _mediatorService;
  final ConnectionOfferRepository _connectionOfferRepository;
  final ChannelService _channelService;
  final ConnectionManager _connectionManager;
  final MatrixService _matrixService;
  final ControlPlaneEventHandlerManagerOptions _options;
  final MeetingPlaceCoreSDKLogger _logger;
  final VdipClient _vdipClient;

  static final String _logKey = 'ChannelActivityEventHandler';

  Future<List<Channel>> process(ChannelActivity channelActivity) async {
    _logger.info(
      'Starting processing event of type ${channelActivity.type}',
      name: _logKey,
    );

    switch (channelActivity.type) {
      case 'channel-inauguration':
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
      case 'chat-activity':
        _logger.info('Processing chat activity event', name: _logKey);
        return ChatActivityEventHandler(
          wallet: _wallet,
          connectionManager: _connectionManager,
          connectionOfferRepository: _connectionOfferRepository,
          channelService: _channelService,
          mediatorService: _mediatorService,
          matrixService: _matrixService,
          options: _options,
          logger: _logger,
        ).process(channelActivity);
      case ChannelActivityType.vdipRequestIssuance ||
          ChannelActivityType.vdipIssuedCredentials:
        _logger.info(
          'Processing VDIP activity event: ${channelActivity.type}',
          name: _logKey,
        );
        return VdipActivityEventHandler(
          wallet: _wallet,
          mediatorService: _mediatorService,
          channelService: _channelService,
          connectionManager: _connectionManager,
          logger: _logger,
          vdipClient: _vdipClient,
        ).process(channelActivity);
      default:
        _logger.warning(
          'Unsupported channel activity type: ${channelActivity.type}',
          name: _logKey,
        );
        return [];
    }
  }

  bool hasChannelActivityBeenProcessed(
    ChannelActivity channelActivity,
    List<DiscoveryEvent> processedEvents,
  ) {
    return processedEvents.firstWhereOrNull(
          (event) =>
              (event.data as ChannelActivity).did == channelActivity.did &&
              (event.data as ChannelActivity).type == channelActivity.type,
        ) !=
        null;
  }
}
