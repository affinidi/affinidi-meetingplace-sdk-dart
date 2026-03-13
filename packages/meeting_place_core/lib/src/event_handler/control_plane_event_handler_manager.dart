import 'dart:async';

import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:meeting_place_mediator/meeting_place_mediator.dart';
import '../entity/channel.dart';
import '../loggers/default_meeting_place_core_sdk_logger.dart';
import '../loggers/meeting_place_core_sdk_logger.dart';
import '../service/channel/channel_service.dart';
import '../service/connection_manager/connection_manager.dart';
import '../repository/repository.dart';
import 'package:ssi/ssi.dart';
import '../service/connection_service.dart';
import '../service/matrix/matrix_service.dart';
import '../service/mediator/mediator_service.dart';
import 'channel_activity_event_handler.dart';
import 'control_plane_event_handler_manager_options.dart';
import 'control_plane_event_stream_manager.dart';
import 'control_plane_stream_event.dart';
import 'exceptions/event_handler_exception.dart';
import 'group_membership_finalised_event_handler.dart';
import 'invitation_accepted_event_handler.dart';
import 'invitation_accepted_group_event_handler.dart';
import 'offer_finalised_event_handler.dart';
import 'outreach_invitation_event_handler.dart';

class ControlPlaneEventManager {
  ControlPlaneEventManager({
    required Wallet wallet,
    required MeetingPlaceMediatorSDK mediatorSDK,
    required MediatorService mediatorService,
    required ControlPlaneSDK controlPlaneSDK,
    required ConnectionService connectionService,
    required ConnectionManager connectionManager,
    required ConnectionOfferRepository connectionOfferRepository,
    required GroupRepository groupRepository,
    required ChannelRepository channelRepository,
    required ChannelService channelService,
    required ControlPlaneEventStreamManager streamManager,
    required DidResolver didResolver,
    required MatrixService matrixService,
    MeetingPlaceCoreSDKLogger? logger,
    ControlPlaneEventHandlerManagerOptions options =
        const ControlPlaneEventHandlerManagerOptions(),
  }) : _streamManager = streamManager,
       _logger =
           logger ?? DefaultMeetingPlaceCoreSDKLogger(className: _className) {
    _invitationAcceptHandler = InvitationAcceptedEventHandler(
      wallet: wallet,
      mediatorService: mediatorService,
      connectionManager: connectionManager,
      channelService: channelService,
      connectionOfferRepository: connectionOfferRepository,
      options: options,
      logger: _logger,
    );
    _invitationGroupAcceptedEventHandler = InvitationGroupAcceptedEventHandler(
      wallet: wallet,
      mediatorService: mediatorService,
      connectionManager: connectionManager,
      connectionOfferRepository: connectionOfferRepository,
      groupRepository: groupRepository,
      channelService: channelService,
      options: options,
      logger: _logger,
    );
    _offerFinalisedEventHandler = OfferFinalisedEventHandler(
      wallet: wallet,
      mediatorService: mediatorService,
      controlPlaneSDK: controlPlaneSDK,
      connectionOfferRepository: connectionOfferRepository,
      channelService: channelService,
      connectionManager: connectionManager,
      didResolver: didResolver,
      options: options,
      logger: _logger,
    );
    _channelActivityEventHandler = ChannelActivityEventHandler(
      wallet: wallet,
      mediatorService: mediatorService,
      connectionOfferRepository: connectionOfferRepository,
      channelService: channelService,
      connectionManager: connectionManager,
      options: options,
      logger: _logger,
    );
    _groupMembershipFinalisedEventHandler =
        GroupMembershipFinalisedEventHandler(
          wallet: wallet,
          mediatorService: mediatorService,
          controlPlaneSDK: controlPlaneSDK,
          connectionManager: connectionManager,
          connectionOfferRepository: connectionOfferRepository,
          groupRepository: groupRepository,
          channelService: channelService,
          matrixService: matrixService,
          options: options,
          logger: _logger,
        );
    _outreachInvitationEventHandler = OutreachInvitationEventHandler(
      wallet: wallet,
      mediatorService: mediatorService,
      connectionManager: connectionManager,
      channelService: channelService,
      connectionService: connectionService,
      connectionOfferRepository: connectionOfferRepository,
      options: options,
      logger: _logger,
    );
  }

  static const String _className = 'DiscoveryEventManager';

  final MeetingPlaceCoreSDKLogger _logger;
  final ControlPlaneEventStreamManager _streamManager;

  late final InvitationAcceptedEventHandler _invitationAcceptHandler;
  late final InvitationGroupAcceptedEventHandler
  _invitationGroupAcceptedEventHandler;
  late final OfferFinalisedEventHandler _offerFinalisedEventHandler;
  late final ChannelActivityEventHandler _channelActivityEventHandler;
  late final GroupMembershipFinalisedEventHandler
  _groupMembershipFinalisedEventHandler;
  late final OutreachInvitationEventHandler _outreachInvitationEventHandler;

  Future<List<DiscoveryEvent<dynamic>>> handleEventsBatch(
    List<DiscoveryEvent> events,
  ) async {
    final methodName = 'handleEventsBatch';
    _logger.info('Started processing batch of events', name: methodName);

    final processedEvents = <DiscoveryEvent>[];

    for (final event in events) {
      try {
        _logger.info('Process event of type ${event.type.name}');
        final channels = await _processEvent(event, processedEvents);
        processedEvents.add(event);

        for (final channel in channels) {
          _streamManager.pushEvent(
            ControlPlaneStreamEvent(channel: channel, type: event.type),
          );
        }
      } on EventHandlerException catch (e, stackTrace) {
        processedEvents.add(event);
        _streamManager.addError(e);
        _logger.error(
          'Failed to process event of type ${event.type.name}: ${e.message}',
          error: e,
          stackTrace: stackTrace,
          name: methodName,
        );
      } catch (e, stackTrace) {
        processedEvents.add(event);
        _streamManager.addError(e);
        _logger.error(
          'Failed to process event of type ${event.type.name}',
          error: e,
          stackTrace: stackTrace,
          name: methodName,
        );
      }
    }

    _logger.info('Completed processing batch of events', name: methodName);
    return processedEvents;
  }

  Future<List<Channel>> _processEvent(
    DiscoveryEvent event,
    List<DiscoveryEvent> processedEvents,
  ) async {
    switch (event.type) {
      case ControlPlaneEventType.InvitationAccept:
        return _invitationAcceptHandler.process(event.data as InvitationAccept);
      case ControlPlaneEventType.InvitationGroupAccept:
        return _invitationGroupAcceptedEventHandler.process(
          event.data as InvitationGroupAccept,
        );
      case ControlPlaneEventType.OfferFinalised:
        return _offerFinalisedEventHandler.process(
          event.data as OfferFinalised,
        );
      case ControlPlaneEventType.ChannelActivity:
        final processedChannelActivities = processedEvents
            .where((e) => e.type == ControlPlaneEventType.ChannelActivity)
            .toList();

        if (_channelActivityEventHandler.hasBeenProcessed(
          event.data,
          processedChannelActivities,
        )) {
          return [];
        }

        return _channelActivityEventHandler.process(
          event.data as ChannelActivity,
        );
      case ControlPlaneEventType.GroupMembershipFinalised:
        return _groupMembershipFinalisedEventHandler.process(
          event.data as GroupMembershipFinalised,
        );
      case ControlPlaneEventType.InvitationOutreach:
        return _outreachInvitationEventHandler.process(
          event.data as InvitationOutreach,
        );
      default:
        _logger.warning('Not implemented: ${event.type.name}');
        return Future.value([]);
    }
  }
}
