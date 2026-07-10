import 'dart:async';

import 'package:matrix/matrix.dart' as matrix;
import 'package:meeting_place_core/meeting_place_core.dart';

import '../../meeting_place_matrix.dart';
import '../call/call_channel_activity_type.dart';
import '../exceptions/meeting_place_livekit_call_exception.dart';
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
  });

  final DidManager didManager;
  final String matrixRoomId;
  final String sfuUrl;
  final String sfuToken;
  final Map<String, String> participantIdToDid;
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
      participantIdToDid: participantIdToDid,
    );
  }

  /// Initialises MatrixRTC and resolves the callId to register against.
  ///
  /// This is the cheap preparation phase that must complete before the
  /// LiveKit room is joined. It does not connect the LiveKit room.
  ///
  /// Both parties reuse an in-progress call generation when one is present so
  /// their E2EE key exchange lands in the same generation: the recipient joins
  /// the caller's call, and a caller whose peer is still in the call rejoins
  /// it. When no generation is present a fresh callId is minted.
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
    _logger.info(
      'Resolved call session: callId=$callId '
      '(existing=${existingCallId != null}) for room $matrixRoomId',
      name: _logKey,
    );
    return callId;
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
  /// Only sent when the caller is alone in the room after connecting, so a
  /// caller that rejoined a still-live call (peer already present) never
  /// re-nudges the callee.
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
