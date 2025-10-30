import 'package:collection/collection.dart';
import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import '../entity/channel.dart';
import '../loggers/meeting_place_core_sdk_logger.dart';
import '../service/mediator/mediator_service.dart';
import 'chat_activity_event_handler.dart';
import '../service/connection_manager/connection_manager.dart';
import '../repository/repository.dart';
import 'package:ssi/ssi.dart';
import 'channel_inauguration_event_handler.dart';
import 'control_plane_event_handler_manager_options.dart';

class ChannelActivityEventHandler {
  ChannelActivityEventHandler({
    required Wallet wallet,
    required MediatorService mediatorService,
    required ConnectionManager connectionManager,
    required ChannelRepository channelRepository,
    required ConnectionOfferRepository connectionOfferRepository,
    required ControlPlaneEventHandlerManagerOptions options,
    required MeetingPlaceCoreSDKLogger logger,
  })  : _wallet = wallet,
        _connectionManager = connectionManager,
        _channelRepository = channelRepository,
        _connectionOfferRepository = connectionOfferRepository,
        _mediatorService = mediatorService,
        _options = options,
        _logger = logger;

  final Wallet _wallet;
  final MediatorService _mediatorService;
  final ConnectionOfferRepository _connectionOfferRepository;
  final ChannelRepository _channelRepository;
  final ConnectionManager _connectionManager;
  final ControlPlaneEventHandlerManagerOptions _options;
  final MeetingPlaceCoreSDKLogger _logger;

  static final String _logKey = 'ChannelActivityEventHandler';

  Future<Channel?> process(ChannelActivity channelActivity) async {
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
        channelRepository: _channelRepository,
        connectionManager: _connectionManager,
        options: _options,
        logger: _logger,
      ).process(channelActivity);
    }

    if (channelActivity.type == 'chat-activity') {
      _logger.info('Processing chat activity event', name: _logKey);
      return ChatActivityEventHandler(
        wallet: _wallet,
        channelRepository: _channelRepository,
        connectionManager: _connectionManager,
        connectionOfferRepository: _connectionOfferRepository,
        mediatorService: _mediatorService,
        logger: _logger,
      ).process(channelActivity);
    }

    _logger.warning(
      'Unsupported channel activity type: ${channelActivity.type}',
      name: _logKey,
    );

    return null;
  }

  bool hasBeenProcessed(
    ChannelActivity channelActivity,
    List<DiscoveryEvent<dynamic>> processedEvents,
  ) {
    return processedEvents.firstWhereOrNull(
          (event) => event.data.did == channelActivity.did,
        ) !=
        null;
  }
}
