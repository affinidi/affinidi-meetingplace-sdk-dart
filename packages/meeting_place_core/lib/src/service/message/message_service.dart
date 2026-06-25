import 'dart:async';

import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:ssi/ssi.dart';

import '../../../meeting_place_core.dart';
import '../../utils/string.dart';
import '../channel/channel_service.dart';
import '../connection_manager/connection_manager.dart';
import '../mediator/mediator_service.dart';
import 'message_service_exception.dart';

class MessageService {
  MessageService({
    required ConnectionManager connectionManager,
    required DidResolver didResolver,
    required MediatorService mediatorService,
    required ChannelService channelService,
    required ControlPlaneSDK controlPlaneSDK,
    required MeetingPlaceCoreSDKLogger logger,
  }) : _didResolver = didResolver,
       _mediatorService = mediatorService,
       _channelService = channelService,
       _controlPlaneSDK = controlPlaneSDK,
       _logger = logger;

  final DidResolver _didResolver;
  final MediatorService _mediatorService;
  final ChannelService _channelService;
  final ControlPlaneSDK _controlPlaneSDK;
  final MeetingPlaceCoreSDKLogger _logger;

  Future<void> sendMessage(
    PlainTextMessage message, {
    required DidManager senderDidManager,
    required String recipientDid,
    required String mediatorDid,
    String? notifyChannelType,
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
      notifyChannel(
        IndividualChannelNotification(
          recipientDid: recipientDid,
          type: notifyChannelType,
        ),
      ).catchError((Object e, StackTrace _) {
        _logger.error(
          '''Failed to send notification for message to ${recipientDid.topAndTail()}''',
          error: e,
          name: 'sendMessage',
        );
      }),
    );
  }

  /// Fires a control-plane channel notification for the given [notification].
  ///
  /// For an [IndividualChannelNotification] this dispatches a
  /// [NotifyChannelCommand] using the stored
  /// `Channel.otherPartyNotificationToken` (no-op if missing).
  /// For a [GroupChannelNotification] this dispatches a
  /// [GroupNotifyChannelCommand] which fans out to all group members.
  Future<void> notifyChannel(ChannelNotification notification) async {
    try {
      switch (notification) {
        case IndividualChannelNotification(
          :final recipientDid,
          :final type,
          :final mediaType,
        ):
          final channel = await _channelService.findChannelByDidOrNull(
            recipientDid,
          );
          final otherPartyNotificationToken =
              channel?.otherPartyNotificationToken;
          if (otherPartyNotificationToken == null) return;

          await _controlPlaneSDK.execute(
            NotifyChannelCommand(
              notificationToken: otherPartyNotificationToken,
              did: recipientDid,
              type: type,
              mediaType: mediaType?.name,
            ),
          );
        case GroupChannelNotification(
          :final offerLink,
          :final groupDid,
          :final type,
        ):
          await _controlPlaneSDK.execute(
            GroupNotifyChannelCommand(
              offerLink: offerLink,
              groupDid: groupDid,
              type: type,
            ),
          );
      }
    } catch (e) {
      _logger.error(
        'Failed to send notification for channel ',
        error: e,
        name: 'notifyChannel',
      );
      throw MessageServiceException.notifyChannelFailed(innerException: e);
    }
  }
}
