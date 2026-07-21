import 'dart:async';

import 'package:matrix/matrix.dart' as matrix;
import 'package:meeting_place_core/meeting_place_core.dart';

import '../../meeting_place_matrix.dart';
import '../call/call_channel_activity_type.dart';
import '../call/mpx_call_event_type.dart';
import '../logger/top_and_tail_extension.dart';
import '../matrix_room_alias.dart';
import '../matrix_service.dart';
import '../matrix_user_id_binding.dart';
import '../transport/call_invite_room_event.dart';
import 'sfu_token_service.dart';

/// Credentials resolved during call setup: DID manager, Matrix room id, SFU
/// URL, SFU token, and the participant-id-to-DID map.
///
/// Returned by [MatrixCallAdapter.fetchCallCredentials].
class CallCredentials {
  const CallCredentials({
    required this.didManager,
    required this.matrixRoomId,
    required this.sfuUrl,
    required this.sfuToken,
    required this.participantIdToDid,
    required this.participantContactCardsByDid,
  });

  final DidManager didManager;
  final String matrixRoomId;
  final String sfuUrl;
  final String sfuToken;
  final Map<String, String> participantIdToDid;
  final Map<String, ContactCard> participantContactCardsByDid;
}

/// Participant identity and contact-card lookups resolved for a call.
class ParticipantDirectory {
  const ParticipantDirectory({
    required this.participantIdToDid,
    required this.participantContactCardsByDid,
  });

  final Map<String, String> participantIdToDid;
  final Map<String, ContactCard> participantContactCardsByDid;
}

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
    required List<String> sfuAllowedHosts,
    required SfuTokenService livekitTokenService,
    required matrix.WebRTCDelegate rtcDelegate,
  }) : _matrixService = matrixService,
       _coreSDK = coreSDK,
       _logger = logger,
       _otherPartyChannelDid = otherPartyChannelDid,
       _livekitSfuUrl = livekitSfuUrl,
       _sfuAllowedHosts = sfuAllowedHosts,
       _livekitTokenService = livekitTokenService,
       _rtcDelegate = rtcDelegate;

  final MatrixService _matrixService;
  final MeetingPlaceCoreSDK _coreSDK;
  final MeetingPlaceMatrixSDKLogger _logger;
  final String _otherPartyChannelDid;
  final Uri? _livekitSfuUrl;
  final List<String> _sfuAllowedHosts;
  final SfuTokenService _livekitTokenService;
  final matrix.WebRTCDelegate _rtcDelegate;

  static const _logKey = 'MatrixCallAdapter';

  /// Recipient must discover the in-progress call's callId before the caller's
  /// ring timeout (60s). Discovery window is 15s to outlast cold app sync, then
  /// fall back to a fresh callId. With 500ms retry interval, this is 30
  /// attempts.
  static const _recipientCallIdDiscoveryWindowMs = 15000;
  static const _recipientCallIdDiscoveryInterval = Duration(milliseconds: 500);
  static const _recipientCallIdDiscoveryAttempts =
      _recipientCallIdDiscoveryWindowMs ~/ 500; // 30 attempts

  /// Matrix room ID of the active call. Set in [registerMatrixCall], cleared in
  /// [leaveCall] to prevent double-cleanup.
  String? get matrixRoomId => _matrixRoomId;
  String? _matrixRoomId;

  /// Group flag and offer link for the resolved call target, cached in
  /// [resolveChannel] so invite/cancel routing stays consistent even when the
  /// resolved channel record is not itself typed as a group channel.
  bool _isGroupCall = false;
  String _offerLink = '';
  Future<void>? _cancelTargetResolution;

  /// MatrixRTC call ID of the active call.
  String? get matrixCallId => _matrixCallId;
  String? _matrixCallId;

  /// Resolves the channel for `_otherPartyChannelDid` and derives the LiveKit
  /// room name.
  ///
  /// Caches the group flag and offer link for consistent invite/cancel routing
  /// via [primeCancelTarget], so cancel messages route correctly even if the
  /// resolved channel record is not explicitly typed as a group channel.
  ///
  /// Throws [MeetingPlaceLiveKitCallOperationException] when the channel or its
  /// permanentChannelDid cannot be resolved.
  Future<({Channel channel, String ownChannelDid, String roomName})>
  resolveChannel() async {
    final existingResolution = _cancelTargetResolution;
    if (existingResolution != null) {
      await existingResolution;
    }
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
    _cancelTargetResolution ??= _resolveCancelTarget(channel);
    await _cancelTargetResolution;
    final isGroupCall = _isGroupCall;
    final roomName = isGroupCall
        ? deriveRoomAliasLocalpart(channelDid: _otherPartyChannelDid)
        : deriveRoomAliasLocalpart(
            channelDid: ownChannelDid,
            otherPartyChannelDid: _otherPartyChannelDid,
          );
    return (channel: channel, ownChannelDid: ownChannelDid, roomName: roomName);
  }

  /// Prepares the call-cancel routing by resolving the channel group status
  /// and caching the offer link and group flag.
  ///
  /// Allows [sendCallCancelToRecipient] to route cancel messages without
  /// awaiting a fresh channel lookup during teardown. Can be called earlier
  /// than [resolveChannel] (before credential resolution) to reduce cancel
  /// latency.
  Future<void> primeCancelTarget() {
    return _cancelTargetResolution ??= _primeCancelTarget();
  }

  /// Fetches all credentials needed to join the LiveKit room: the DID manager,
  /// Matrix room ID, OpenID token, device ID, participant DID lookup,
  /// participant contact cards, SFU JWT, and the resolved SFU URL.
  ///
  /// Called after [resolveChannel] to fetch credentials for the resolved
  /// channel and room name. Validates the SFU URL against the allowlist.
  ///
  /// Throws [MeetingPlaceLiveKitCallOperationException] when no SFU URL is
  /// available or the URL fails security validation.
  Future<CallCredentials> fetchCallCredentials({
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
    final participantDirectory = await _buildParticipantDirectory(
      channel: channel,
      ownChannelDid: ownChannelDid,
      serverName: openIdToken.matrixServerName,
    );
    final tokenResponse = await _livekitTokenService.fetchToken(
      roomName: roomName,
      openIdCredentials: openIdToken,
      deviceId: deviceId,
    );
    final rawSfuUrl = _livekitSfuUrl?.toString() ?? tokenResponse.url;
    final isServerSupplied = _livekitSfuUrl == null;
    final sfuUrl = _validateSfuUrl(
      rawSfuUrl,
      _sfuAllowedHosts,
      isServerSupplied: isServerSupplied,
    ).toString();
    return CallCredentials(
      didManager: didManager,
      matrixRoomId: matrixRoomId,
      sfuUrl: sfuUrl,
      sfuToken: tokenResponse.token,
      participantIdToDid: participantDirectory.participantIdToDid,
      participantContactCardsByDid:
          participantDirectory.participantContactCardsByDid,
    );
  }

  /// Initialises MatrixRTC and resolves the callId.
  ///
  /// Stores identifiers here (not in [registerMatrixCall]) so they're
  /// available for [sendCallCancelToRecipient] before registration completes,
  /// preventing race conditions during early hangups.
  ///
  /// Reuses in-progress calls when present; otherwise generates a fresh callId.
  Future<String> prepareCallSession({
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
    final callId =
        existingCallId ??
        '$matrixRoomId@${DateTime.now().microsecondsSinceEpoch}';
    _matrixRoomId = matrixRoomId;
    _matrixCallId = callId;
    _logger.info(
      'Resolved call session: callId=$callId '
      '(existing=${existingCallId != null}) for room $matrixRoomId',
      name: _logKey,
    );
    return callId;
  }

  /// Signals the Matrix homeserver that a video call has started.
  ///
  /// Called after [prepareCallSession] once the LiveKit room is connected.
  /// The matrix room ID and call ID are already stored in [prepareCallSession],
  /// so this method only notifies the homeserver of the active call.
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
  }

  /// Sends a call-invite nudge via the control-plane pipeline.
  ///
  /// Only sent when the caller is alone; skipped if rejoining an existing call.
  /// Routes to group channel notification or (for individual calls) room event
  /// plus channel notification.
  Future<void> sendCallInvite({
    required Channel channel,
    required String matrixRoomId,
    CallMediaType mediaType = CallMediaType.video,
  }) async {
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
        _coreSDK.notifyChannel(event.notification!).catchError((
          Object error,
          StackTrace st,
        ) {
          _logger.error(
            'Failed to send call-invite notification to control plane.',
            error: error,
            stackTrace: st,
            name: _logKey,
          );
        }),
      );
    }
    _logger.info(
      'Sent call-invite nudge to ${_otherPartyChannelDid.topAndTail()}',
      name: _logKey,
    );
  }

  /// Sends a `call-decline` nudge when hanging up pre-answer.
  ///
  /// Routes via cached group flag/offer-link; does not await channel lookup
  /// (call session disposes immediately after). Falls back to preparing cancel
  /// target if not yet resolved. Routes to room event (group) or channel
  /// notification (individual).
  Future<void> sendCallCancelToRecipient() async {
    _logger.info(
      'Sending call-cancel nudge to ${_otherPartyChannelDid.topAndTail()}',
      name: _logKey,
    );
    if (_cancelTargetResolution == null) {
      try {
        await primeCancelTarget();
        await sendCallCancelToRecipient();
      } catch (error, stackTrace) {
        _logger.error(
          'Failed to resolve call-cancel target for '
          '${_otherPartyChannelDid.topAndTail()}',
          error: error,
          stackTrace: stackTrace,
          name: _logKey,
        );
      }
      return;
    }
    if (_isGroupCall && _matrixRoomId != null) {
      final matrixRoomId = _matrixRoomId!;
      try {
        await _sendGroupCallCancelRoomEvent(matrixRoomId);
      } catch (error, stackTrace) {
        _logger.error(
          'Failed to send group call cancel room event.',
          error: error,
          stackTrace: stackTrace,
          name: _logKey,
        );
      }
      return;
    }
    final notification = _isGroupCall
        ? GroupChannelNotification(
            offerLink: _offerLink,
            groupDid: _otherPartyChannelDid,
            type: CallChannelActivityType.callDecline,
          )
        : IndividualChannelNotification(
            recipientDid: _otherPartyChannelDid,
            type: CallChannelActivityType.callDecline,
          );
    try {
      await _coreSDK.notifyChannel(notification);
    } catch (error, stackTrace) {
      _logger.error(
        'Failed to send call-cancel nudge to '
        '${_otherPartyChannelDid.topAndTail()}',
        error: error,
        stackTrace: stackTrace,
        name: _logKey,
      );
    }
  }

  /// Signals the Matrix homeserver that the call has ended and clears
  /// identifiers.
  ///
  /// Idempotent: safe to call multiple times.
  Future<void> leaveCall() async {
    final roomId = _matrixRoomId;
    final callId = _matrixCallId;
    _matrixRoomId = null;
    _matrixCallId = null;
    if (roomId != null && callId != null) {
      await _matrixService.leaveCall(roomId: roomId, callId: callId);
    }
  }

  /// Clears the stored identifiers without sending a leave signal.
  ///
  /// Use when the Matrix leave is handled elsewhere (e.g., `dispose` via
  /// unawaited). Prevents [leaveCall] from attempting a duplicate signal.
  void clearIds() {
    _matrixRoomId = null;
    _matrixCallId = null;
  }

  /// Sends a call-cancel room event to the Matrix room for group calls.
  Future<void> _sendGroupCallCancelRoomEvent(String matrixRoomId) async {
    final ownChannelDid = await _resolveOwnChannelDidForCancel();
    if (ownChannelDid == null) return;
    final didManager = await _coreSDK.getDidManager(ownChannelDid);
    await _matrixService
        .sendRoomEvent(matrixRoomId, MpxCallEventType.callCancel, {
          'callerPermanentChannelDid': ownChannelDid,
          if (_matrixCallId != null) 'callId': _matrixCallId,
        }, didManager: didManager);
  }

  /// Resolves the caller's channel DID for sending cancel notifications.
  Future<String?> _resolveOwnChannelDidForCancel() async {
    final channel = await _coreSDK.getChannelByOtherPartyPermanentDid(
      _otherPartyChannelDid,
    );
    return channel?.permanentChannelDid;
  }

  /// Resolves whether the call target is a group and caches the group flag.
  Future<void> _resolveCancelTarget(Channel channel) async {
    _offerLink = channel.offerLink;
    if (channel.isGroup) {
      _isGroupCall = true;
      return;
    }
    final group = await _coreSDK.getGroupByOfferLink(channel.offerLink);
    _isGroupCall = group != null;
  }

  /// Prepares the cancel target by looking up the channel if not already
  /// resolved.
  Future<void> _primeCancelTarget() async {
    final channel = await _coreSDK.getChannelByOtherPartyPermanentDid(
      _otherPartyChannelDid,
    );
    if (channel == null) return;
    await _resolveCancelTarget(channel);
  }

  /// Validates the SFU URL for security: enforces wss:// scheme and checks
  /// against the allowlist when configured.
  ///
  /// Throws [MeetingPlaceLiveKitCallOperationException] if:
  /// - The URL is null, empty, or invalid.
  /// - The scheme is not `wss` (server-supplied URLs), or not `wss`/`ws`
  ///   (app-supplied URLs, where [isServerSupplied] is false).
  /// - [isServerSupplied] is true and [allowedHosts] is empty (production
  ///   mode requires allowlist).
  /// - The host is not in [allowedHosts] when the list is non-empty.
  ///
  /// Supports wildcard patterns in [allowedHosts] (e.g. `*.example.com`).
  Uri _validateSfuUrl(
    String? rawUrl,
    List<String> allowedHosts, {
    required bool isServerSupplied,
  }) {
    if (rawUrl == null || rawUrl.isEmpty) {
      throw const MeetingPlaceLiveKitCallOperationException(
        'No LiveKit SFU URL available: set livekitSfuUrl in plugin options '
        'or ensure lk-jwt-service returns a URL in the response',
      );
    }
    final uri = Uri.tryParse(rawUrl);
    // Server-supplied URLs must use wss:// (TLS). App-supplied URLs
    // (livekitSfuUrl) may use ws:// for local development, since the
    // application controls the value and it cannot be tampered with by a
    // compromised JWT service.
    final schemeIsAllowed = isServerSupplied
        ? uri?.scheme == 'wss'
        : uri?.scheme == 'wss' || uri?.scheme == 'ws';
    if (uri == null || !schemeIsAllowed) {
      final allowedSchemes = isServerSupplied ? 'wss://' : 'wss:// or ws://';
      throw MeetingPlaceLiveKitCallOperationException(
        'SFU URL must use $allowedSchemes scheme, '
        'got: ${uri?.scheme ?? "null"}',
      );
    }
    // Production requirement: server-supplied URLs must have allowlist. This
    // is also enforced eagerly in the plugin constructor; kept here as a
    // defense-in-depth check at the connection choke point.
    if (isServerSupplied && allowedHosts.isEmpty) {
      throw const MeetingPlaceLiveKitCallOperationException(
        'Security violation: sfuAllowedHosts must be configured when using '
        'server-supplied SFU URLs (livekitSfuUrl is null). '
        'Set sfuAllowedHosts '
        'in plugin options to prevent compromised JWT services from redirecting'
        ' media to attacker-controlled servers.',
      );
    }
    if (allowedHosts.isNotEmpty) {
      final host = uri.host;
      if (!_hostMatchesAllowlist(host, allowedHosts)) {
        throw MeetingPlaceLiveKitCallOperationException(
          'SFU host "$host" is not in the allowlist',
        );
      }
    }
    return uri;
  }

  /// Returns whether [host] matches any entry in [allowedHosts].
  ///
  /// A `*.` prefix is a single-label wildcard: `*.affinidi.io` matches
  /// `livekit.affinidi.io` but not the apex `affinidi.io` nor deeper
  /// subdomains such as `evil.sub.affinidi.io`. All other entries require an
  /// exact host match.
  bool _hostMatchesAllowlist(String host, List<String> allowedHosts) {
    return allowedHosts.any((pattern) {
      if (pattern.startsWith('*.')) {
        final suffix = pattern.substring(
          1,
        ); // '*.affinidi.io' -> '.affinidi.io'
        if (!host.endsWith(suffix)) return false;
        final label = host.substring(0, host.length - suffix.length);
        // Wildcard covers exactly one label; reject empty or dotted labels.
        return label.isNotEmpty && !label.contains('.');
      }
      return host == pattern;
    });
  }

  /// Discovers an in-progress call ID on the recipient side within a time
  /// window.
  Future<String?> _resolveExistingCallId({
    required DidManager didManager,
    required String roomId,
    required bool isRecipient,
  }) async {
    if (!isRecipient) return null;

    for (
      var attempt = 0;
      attempt < _recipientCallIdDiscoveryAttempts;
      attempt++
    ) {
      if (attempt > 0) {
        await Future<void>.delayed(_recipientCallIdDiscoveryInterval);
      }
      final callId = await _matrixService.activeCallId(
        didManager: didManager,
        roomId: roomId,
      );
      if (callId != null) {
        _logger.info(
          'Discovered in-progress callId on attempt ${attempt + 1}: $callId',
          name: _logKey,
        );
        return callId;
      }
    }
    return null;
  }

  /// Builds the participant directory with Matrix user IDs and contact cards
  /// for the call.
  Future<ParticipantDirectory> _buildParticipantDirectory({
    required Channel channel,
    required String ownChannelDid,
    required String serverName,
  }) async {
    final participantIdToDid = <String, String>{};
    final participantContactCardsByDid = <String, ContactCard>{};

    void addParticipant(String did, ContactCard? card) {
      participantIdToDid[deriveMatrixUserId(did, serverName)] = did;
      if (card != null) {
        participantContactCardsByDid[did] = card;
      }
    }

    addParticipant(ownChannelDid, channel.contactCard);

    if (channel.isGroup) {
      final group = await _coreSDK.getGroupByOfferLink(channel.offerLink);
      if (group != null) {
        for (final member in group.members) {
          addParticipant(member.did, member.contactCard);
        }
      }
    } else {
      addParticipant(_otherPartyChannelDid, channel.otherPartyContactCard);
    }
    return ParticipantDirectory(
      participantIdToDid: participantIdToDid,
      participantContactCardsByDid: participantContactCardsByDid,
    );
  }
}
