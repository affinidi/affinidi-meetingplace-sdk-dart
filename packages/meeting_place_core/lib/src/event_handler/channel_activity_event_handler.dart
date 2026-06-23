import 'dart:async';

import 'package:collection/collection.dart';
import 'package:meeting_place_control_plane/meeting_place_control_plane.dart'
    hide ChannelActivityType;
import 'package:ssi/ssi.dart';

import '../call/call_decline_signal.dart';
import '../call/call_media_type.dart';
import '../call/incoming_call_signal.dart';
import '../call/mpx_call_event_type.dart';
import '../entity/channel.dart';
import '../loggers/meeting_place_core_sdk_logger.dart';
import '../repository/repository.dart';
import '../service/channel/channel_service.dart';
import '../service/connection_manager/connection_manager.dart';
import '../service/matrix/matrix_service.dart';
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
    required MatrixService matrixService,
    required ControlPlaneEventHandlerManagerOptions options,
    required MeetingPlaceCoreSDKLogger logger,
    required StreamController<IncomingCallSignal> incomingCallSignalController,
    required StreamController<CallDeclineSignal> callDeclineSignalController,
  }) : _wallet = wallet,
       _connectionManager = connectionManager,
       _channelService = channelService,
       _connectionOfferRepository = connectionOfferRepository,
       _mediatorService = mediatorService,
       _matrixService = matrixService,
       _options = options,
       _logger = logger,
       _incomingCallSignalController = incomingCallSignalController,
       _callDeclineSignalController = callDeclineSignalController;

  final Wallet _wallet;
  final MediatorService _mediatorService;
  final ConnectionOfferRepository _connectionOfferRepository;
  final ChannelService _channelService;
  final ConnectionManager _connectionManager;
  final MatrixService _matrixService;
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
        ).process(channelActivity);
      case ChannelActivityType.callInvite:
        _logger.info(
          'Processing call-invite signal for channel'
          ' ${channelActivity.did.topAndTail()}',
          name: _logKey,
        );
        final mediaType = await _fetchCallMediaType(channelActivity);
        _incomingCallSignalController.add(
          IncomingCallSignal(
            ownChannelDid: channelActivity.did,
            mediaType: mediaType,
          ),
        );
        // Return [] — this is not a chat/badge event; the plugin handles ringing.
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

  /// Fetches the [CallMediaType] for an incoming `call-invite` by reading the
  /// `mpx.call.invite` Matrix room event written by the caller.
  ///
  /// Forces a one-shot sync first, because the control-plane nudge usually
  /// arrives before the Matrix room event has reached the recipient's local
  /// timeline. The sync pulls the latest server-side events in one round-trip,
  /// so this stays snappy and deterministic.
  ///
  /// Falls back to [CallMediaType.video] when the event is missing or the
  /// Matrix room is unavailable.
  Future<CallMediaType> _fetchCallMediaType(
    ChannelActivity channelActivity,
  ) async {
    try {
      final channel = await _channelService.findChannelByDid(
        channelActivity.did,
      );
      final roomId = channel.matrixRoomId;
      if (roomId == null) {
        _logger.warning(
          'No Matrix room ID for channel, defaulting to video',
          name: _logKey,
        );
        return CallMediaType.video;
      }

      final did =
          channel.permanentChannelDid ??
          (throw StateError(
            'Channel has no permanentChannelDid: ${channel.id}',
          ));
      final didManager = await _connectionManager.getDidManagerForDid(
        _wallet,
        did,
      );

      final history = await _matrixService.fetchRoomHistory(
        roomId,
        didManager: didManager,
        forceSync: true,
      );

      final inviteEvent = history.firstWhereOrNull(
        (e) => e.type == MpxCallEventType.callInvite,
      );
      if (inviteEvent == null) {
        _logger.warning(
          'No mpx.call.invite event in room history (fetched ${history.length}'
          ' events), defaulting to video',
          name: _logKey,
        );
        return CallMediaType.video;
      }

      final mediaTypeStr = inviteEvent.content['mediaType'] as String?;
      if (mediaTypeStr == null) {
        _logger.warning(
          'mediaType not found in invite event content, defaulting to video',
          name: _logKey,
        );
        return CallMediaType.video;
      }

      final mediaType = CallMediaType.values.firstWhereOrNull(
        (m) => m.name == mediaTypeStr,
      );
      if (mediaType == null) {
        _logger.warning(
          'Unknown mediaType value: $mediaTypeStr, defaulting to video',
          name: _logKey,
        );
        return CallMediaType.video;
      }

      _logger.info(
        'Resolved call media type: ${mediaType.name}',
        name: _logKey,
      );
      return mediaType;
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to fetch call media type, defaulting to video',
        error: e,
        stackTrace: stackTrace,
        name: _logKey,
      );
      return CallMediaType.video;
    }
  }
}
