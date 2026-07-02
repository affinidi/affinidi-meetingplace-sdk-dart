import 'dart:async';

import 'package:matrix/matrix.dart' as matrix;
import 'package:meeting_place_core/meeting_place_core.dart';

import '../../meeting_place_matrix.dart';
import '../logger/top_and_tail_extension.dart';
import '../transport/call_invite_room_event.dart';
import 'sfu_token_service.dart';

/// Owns all Matrix and control-plane interactions for a single call session.
///
/// Handles channel/credential resolution, MatrixRTC session preparation, call
/// registration, invite/cancel nudges, and Matrix call cleanup. Stores the
/// Matrix room and call identifiers so the service can retrieve them for
/// teardown without holding SDK references directly.
///
/// Constructed by the call service at creation time. The plugin
/// remains unchanged.
class MatrixCallAdapter {
  MatrixCallAdapter({
    required MatrixService matrixService,
    required MeetingPlaceCoreSDK coreSDK,
    required MeetingPlaceMatrixSDKLogger logger,
    required String otherPartyChannelDid,
    required Uri? livekitSfuUrl,
    required SfuTokenService livekitTokenService,
    required matrix.WebRTCDelegate rtcDelegate,
  }) : _matrixService = matrixService,
       _coreSDK = coreSDK,
       _logger = logger,
       _otherPartyChannelDid = otherPartyChannelDid,
       _livekitSfuUrl = livekitSfuUrl,
       _livekitTokenService = livekitTokenService,
       _rtcDelegate = rtcDelegate;

  final MatrixService _matrixService;
  final MeetingPlaceCoreSDK _coreSDK;
  final MeetingPlaceMatrixSDKLogger _logger;
  final String _otherPartyChannelDid;
  final Uri? _livekitSfuUrl;
  final SfuTokenService _livekitTokenService;
  final matrix.WebRTCDelegate _rtcDelegate;

  static const _logKey = 'MatrixCallAdapter';

  /// Number of times a recipient retries discovering the in-progress call's
  /// callId before giving up, to absorb state-sync lag behind the call-invite.
  static const _recipientCallIdDiscoveryAttempts = 5;

  /// Delay between recipient callId-discovery attempts.
  static const _recipientCallIdDiscoveryInterval = Duration(milliseconds: 300);

  /// Matrix room ID of the active call. Set in [registerMatrixCall], cleared in
  /// [leaveCall] to prevent double-cleanup.
  String? get matrixRoomId => _matrixRoomId;
  String? _matrixRoomId;

  /// MatrixRTC call ID of the active call.
  String? get matrixCallId => _matrixCallId;
  String? _matrixCallId;

  /// Resolves the channel for `_otherPartyChannelDid` and derives the LiveKit
  /// room name.
  ///
  /// Throws [MeetingPlaceLiveKitCallOperationException] when the channel or its
  /// permanentChannelDid cannot be resolved.
  Future<({Channel channel, String ownChannelDid, String roomName})>
  resolveChannel() async {
    final channel = await _coreSDK.getChannelByOtherPartyPermanentDid(
      _otherPartyChannelDid,
    );
    if (channel == null) {
      throw MeetingPlaceLiveKitCallOperationException(
        'No channel found for contact DID: $_otherPartyChannelDid',
      );
    }
    final ownChannelDid = channel.permanentChannelDid;
    if (ownChannelDid == null) {
      throw MeetingPlaceLiveKitCallOperationException(
        'Channel for contact $_otherPartyChannelDid has no permanentChannelDid',
      );
    }
    final roomName = channel.isGroup
        ? deriveRoomAliasLocalpart(channelDid: _otherPartyChannelDid)
        : deriveRoomAliasLocalpart(
            channelDid: ownChannelDid,
            otherPartyChannelDid: _otherPartyChannelDid,
          );
    return (channel: channel, ownChannelDid: ownChannelDid, roomName: roomName);
  }

  /// Fetches all credentials needed to join the LiveKit room: the DID manager,
  /// Matrix room id, OpenID token, device id, participant-id-to-DID map, SFU
  /// JWT, and the resolved SFU URL.
  ///
  /// Throws [MeetingPlaceLiveKitCallOperationException] when no SFU URL is
  /// available.
  Future<
    ({
      DidManager didManager,
      String matrixRoomId,
      String sfuUrl,
      String sfuToken,
      Map<String, String> participantIdToDid,
    })
  >
  fetchCallCredentials({
    required Channel channel,
    required String ownChannelDid,
    required String roomName,
  }) async {
    final didManager = await _coreSDK.getDidManager(ownChannelDid);
    final matrixRoomId = await _matrixService.resolveRoomIdForChannel(
      didManager: didManager,
      channel: channel,
    );
    final openIdToken = await _matrixService.getOpenIdToken(didManager);
    final deviceId = await _matrixService.getDeviceId(didManager);
    final participantIdToDid = await _buildParticipantIdToDidMap(
      channel: channel,
      ownChannelDid: ownChannelDid,
      serverName: openIdToken.matrixServerName,
    );
    final tokenResponse = await _livekitTokenService.fetchToken(
      roomName: roomName,
      openIdCredentials: openIdToken,
      deviceId: deviceId,
    );
    final sfuUrl = _livekitSfuUrl?.toString() ?? tokenResponse.url;
    if (sfuUrl == null) {
      throw const MeetingPlaceLiveKitCallOperationException(
        'No LiveKit SFU URL available: set livekitSfuUrl in plugin options '
        'or ensure lk-jwt-service returns a URL in the response',
      );
    }
    return (
      didManager: didManager,
      matrixRoomId: matrixRoomId,
      sfuUrl: sfuUrl,
      sfuToken: tokenResponse.token,
      participantIdToDid: participantIdToDid,
    );
  }

  /// Initialises MatrixRTC and checks for an in-progress call.
  ///
  /// This is the cheap preparation phase that must complete before the
  /// call-invite nudge is sent, so the rejoin decision is known. It does not
  /// connect the LiveKit room.
  ///
  /// Returns whether a call was already in progress in the room before this
  /// device joined (rejoin scenario), and the callId to register against.
  Future<({bool callAlreadyInProgress, String callId})> prepareCallSession({
    required DidManager didManager,
    required String matrixRoomId,
    required bool isRecipient,
  }) async {
    await _matrixService.initializeVoIPWithDelegate(
      didManager: didManager,
      delegate: _rtcDelegate,
    );

    final existingCallId = await _resolveExistingCallId(
      didManager: didManager,
      roomId: matrixRoomId,
      isRecipient: isRecipient,
    );
    final callAlreadyInProgress = existingCallId != null;
    final callId =
        existingCallId ??
        '$matrixRoomId@${DateTime.now().microsecondsSinceEpoch}';
    _logger.info(
      'Active call membership check: '
      'callAlreadyInProgress=$callAlreadyInProgress callId=$callId'
      ' for room $matrixRoomId',
      name: _logKey,
    );
    return (callAlreadyInProgress: callAlreadyInProgress, callId: callId);
  }

  /// Signals the Matrix homeserver that a video call has started and stores the
  /// room/call identifiers for cleanup via [leaveCall].
  Future<void> registerMatrixCall({
    required DidManager didManager,
    required String matrixRoomId,
    required String callId,
    required String sfuUrl,
    required String roomName,
  }) async {
    await _matrixService.startCall(
      didManager: didManager,
      roomId: matrixRoomId,
      callId: callId,
      livekitServiceUrl: sfuUrl,
      livekitAlias: roomName,
    );
    _matrixRoomId = matrixRoomId;
    _matrixCallId = callId;
  }

  /// Sends a call-invite nudge to [channel] via the control-plane pipeline.
  ///
  /// No-ops silently when [callAlreadyInProgress] is true: this is a rejoin
  /// (e.g. after an app restart) and a duplicate invite must not be sent.
  Future<void> sendCallInvite({
    required Channel channel,
    required bool callAlreadyInProgress,
    required String matrixRoomId,
    CallMediaType mediaType = CallMediaType.video,
  }) async {
    if (callAlreadyInProgress) {
      _logger.warning(
        'Skipping call-invite nudge to '
        '${_otherPartyChannelDid.topAndTail()}: rejoining in-progress call',
        name: _logKey,
      );
      return;
    }
    if (channel.isGroup) {
      await _coreSDK.notifyChannel(
        GroupChannelNotification(
          offerLink: channel.offerLink,
          groupDid: _otherPartyChannelDid,
          type: mediaType == CallMediaType.audio
              ? CallChannelActivityType.callInviteAudio
              : CallChannelActivityType.callInviteVideo,
        ),
      );
    } else {
      final senderDid = channel.permanentChannelDid!;
      final event = CallInviteRoomEvent(
        senderDid: senderDid,
        mediaType: mediaType,
        recipientDid: _otherPartyChannelDid,
      );
      final didManager = await _coreSDK.getDidManager(senderDid);
      await _matrixService.sendRoomEvent(
        matrixRoomId,
        event.type,
        event.content,
        didManager: didManager,
      );
      unawaited(
        _coreSDK
            .notifyChannel(event.notification!)
            .catchError((Object _, StackTrace _) {}),
      );
    }
    _logger.info(
      'Sent call-invite nudge to ${_otherPartyChannelDid.topAndTail()}',
      name: _logKey,
    );
  }

  /// Sends a `call-decline` nudge to the other party. Used when the caller
  /// hangs up or times out before the call is answered. Individual calls only.
  void sendCallCancelToRecipient() {
    _logger.info(
      'Sending call-cancel nudge to ${_otherPartyChannelDid.topAndTail()}',
      name: _logKey,
    );
    unawaited(
      _coreSDK.notifyChannel(
        IndividualChannelNotification(
          recipientDid: _otherPartyChannelDid,
          type: CallChannelActivityType.callDecline,
        ),
      ),
    );
  }

  /// Leaves the active Matrix call and clears the stored identifiers.
  ///
  /// Idempotent: no-op when no call is registered or identifiers have already
  /// been cleared.
  Future<void> leaveCall() async {
    final roomId = _matrixRoomId;
    final callId = _matrixCallId;
    _matrixRoomId = null;
    _matrixCallId = null;
    if (roomId != null && callId != null) {
      await _matrixService.leaveCall(roomId: roomId, callId: callId);
    }
  }

  /// Clears the stored identifiers without sending a leave signal. Use when
  /// the Matrix leave is handled elsewhere (e.g. `dispose` via unawaited).
  void clearIds() {
    _matrixRoomId = null;
    _matrixCallId = null;
  }

  Future<String?> _resolveExistingCallId({
    required DidManager didManager,
    required String roomId,
    required bool isRecipient,
  }) async {
    final attempts = isRecipient ? _recipientCallIdDiscoveryAttempts : 1;
    for (var attempt = 0; attempt < attempts; attempt++) {
      final callId = await _matrixService.activeCallId(
        didManager: didManager,
        roomId: roomId,
      );
      if (callId != null) return callId;
      if (attempt < attempts - 1) {
        await Future<void>.delayed(_recipientCallIdDiscoveryInterval);
      }
    }
    return null;
  }

  Future<Map<String, String>> _buildParticipantIdToDidMap({
    required Channel channel,
    required String ownChannelDid,
    required String serverName,
  }) async {
    final dids = <String>{ownChannelDid};
    if (channel.isGroup) {
      final group = await _coreSDK.getGroupByOfferLink(channel.offerLink);
      if (group != null) {
        dids.addAll(group.members.map((member) => member.did));
      }
    } else {
      dids.add(_otherPartyChannelDid);
    }
    return {for (final did in dids) deriveMatrixUserId(did, serverName): did};
  }
}
