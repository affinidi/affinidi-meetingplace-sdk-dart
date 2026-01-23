import 'dart:async';

import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:ssi/ssi.dart';

import '../../../meeting_place_core.dart';
import '../../utils/string.dart';
import '../connection_manager/connection_manager.dart';
import '../mediator/mediator_service.dart';
import 'message_service_exception.dart';

class MessageService {
  MessageService({
    required ConnectionManager connectionManager,
    required DidResolver didResolver,
    required MediatorService mediatorService,
    required ChannelRepository channelRepository,
    required ControlPlaneSDK controlPlaneSDK,
    required MeetingPlaceCoreSDKLogger logger,
  }) : _didResolver = didResolver,
       _mediatorService = mediatorService,
       _channelRepository = channelRepository,
       _controlPlaneSDK = controlPlaneSDK,
       _logger = logger;

  final DidResolver _didResolver;
  final MediatorService _mediatorService;
  final ChannelRepository _channelRepository;
  final ControlPlaneSDK _controlPlaneSDK;
  final MeetingPlaceCoreSDKLogger _logger;

  Future<void> sendMessage(
    PlainTextMessage message, {
    required DidManager senderDidManager,
    required String recipientDid,
    required String mediatorDid,
    NotifyChannelType? notifyChannelType,
    bool ephemeral = false,
    int? forwardExpiryInSeconds,
  }) async {
    final recipientDidDocument = await _didResolver.resolveDid(recipientDid);

    await _mediatorService.sendMessage(
      message,
      senderDidManager: senderDidManager,
      recipientDidDocument: recipientDidDocument,
      mediatorDid: mediatorDid,
      ephemeral: ephemeral,
      forwardExpiryInSeconds: forwardExpiryInSeconds,
    );

    if (notifyChannelType == null) return;

    unawaited(
      _notifyChannel(
        recipientDid: recipientDid,
        notifyChannelType: notifyChannelType,
      ).catchError((e) {
        _logger.error(
          '''Failed to send notification for message to ${recipientDid.topAndTail()}''',
          error: e,
          name: 'sendMessage',
        );
      }),
    );
  }

  Future<void> _notifyChannel({
    required String recipientDid,
    required NotifyChannelType notifyChannelType,
  }) async {
    final channel = await _channelRepository.findChannelByDid(recipientDid);

    final otherPartyNotificationToken = channel?.otherPartyNotificationToken;
    if (otherPartyNotificationToken == null) return;

    try {
      await _controlPlaneSDK.notifyChannel(
        notificationToken: otherPartyNotificationToken,
        did: recipientDid,
        type: notifyChannelType,
      );
    } catch (e) {
      _logger.error(
        'Failed to send notification for channel ',
        error: e,
        name: 'sendMessage',
      );
      throw MessageServiceException.notifyChannelFailed(innerException: e);
    }
  }
}
