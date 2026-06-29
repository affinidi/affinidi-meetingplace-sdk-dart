import 'dart:async';

import 'package:collection/collection.dart';
import 'package:meeting_place_control_plane/meeting_place_control_plane.dart'
    hide ChannelActivityType;
import 'package:ssi/ssi.dart';

import '../call/call_decline_signal.dart';
import '../call/call_media_type.dart';
import '../call/incoming_call_signal.dart';
import '../entity/channel.dart';
import '../loggers/meeting_place_core_sdk_logger.dart';
import '../repository/repository.dart';
import '../service/channel/channel_service.dart';
import '../service/connection_manager/connection_manager.dart';
import '../transport/meeting_place_transport.dart';
import '../service/mediator/mediator_service.dart';
import '../utils/string.dart';
import '../vdip/channel_activity_type.dart';
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
    required MeetingPlaceTransport channelTransport,
    required ControlPlaneEventHandlerManagerOptions options,
    required MeetingPlaceCoreSDKLogger logger,
    required StreamController<IncomingCallSignal> incomingCallSignalController,
    required StreamController<CallDeclineSignal> callDeclineSignalController,
  }) : _wallet = wallet,
       _connectionManager = connectionManager,
       _channelService = channelService,
       _connectionOfferRepository = connectionOfferRepository,
       _mediatorService = mediatorService,
       _channelTransport = channelTransport,
       _options = options,
       _logger = logger,
       _incomingCallSignalController = incomingCallSignalController,
       _callDeclineSignalController = callDeclineSignalController;

  final Wallet _wallet;
  final MediatorService _mediatorService;
  final ConnectionOfferRepository _connectionOfferRepository;
  final ChannelService _channelService;
  final ConnectionManager _connectionManager;
  final MeetingPlaceTransport _channelTransport;
  final ControlPlaneEventHandlerManagerOptions _options;
  final MeetingPlaceCoreSDKLogger _logger;
  final StreamController<IncomingCallSignal> _incomingCallSignalController;
  final StreamController<CallDeclineSignal> _callDeclineSignalController;

  static final String _logKey = 'ChannelActivityEventHandler';

  Future<List<Channel>> process(ChannelActivity channelActivity) async {
    _logger.info(
      'Starting processing event of type ${channelActivity.type}',
      name: _logKey,
    );

    switch (channelActivity.type) {
      case ChannelActivityType.channelInauguration:
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
      case ChannelActivityType.chatActivity:
        _logger.info('Processing chat activity event', name: _logKey);
        return ChatActivityEventHandler(
          wallet: _wallet,
          connectionManager: _connectionManager,
          connectionOfferRepository: _connectionOfferRepository,
          channelService: _channelService,
          mediatorService: _mediatorService,
          channelTransport: _channelTransport,
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
        ).process(channelActivity);
      case ChannelActivityType.callInvite:
        _logger.info(
          'Processing call-invite signal for channel'
          ' ${channelActivity.did.topAndTail()}',
          name: _logKey,
        );
        _incomingCallSignalController.add(
          IncomingCallSignal(
            ownChannelDid: channelActivity.did,
            mediaType: _parseMediaType(channelActivity.mediaType),
          ),
        );
        return [];
      case ChannelActivityType.callDecline:
        _logger.info(
          'Processing call-decline signal for channel'
          ' ${channelActivity.did.topAndTail()}',
          name: _logKey,
        );
        _callDeclineSignalController.add(
          CallDeclineSignal(ownChannelDid: channelActivity.did),
        );
        return [];
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

  /// Maps the control-plane `call-invite` media-type string to a
  /// [CallMediaType], falling back to [CallMediaType.video] when the caller
  /// did not supply one (e.g. an older client).
  CallMediaType _parseMediaType(String? mediaType) {
    return CallMediaType.values.firstWhereOrNull((m) => m.name == mediaType) ??
        CallMediaType.video;
  }
}
