import 'dart:async';
import 'dart:typed_data';

import 'package:matrix/matrix.dart' as matrix;
import 'package:meeting_place_control_plane/meeting_place_control_plane.dart'
    show ControlPlaneSDK;
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meta/meta.dart';
import 'package:ssi/ssi.dart';

import '../meeting_place_matrix.dart';

import 'matrix_sender_did_resolver.dart';

/// A [MeetingPlaceCoreSDK] backed by a Matrix homeserver.
///
/// Implements [MeetingPlaceCoreSDK] via composition, delegating all core
/// behaviour to an inner [_coreSDK] instance and intercepting only
/// Matrix-specific transport calls. The additional [matrixService] field
/// exposes matrix-specific APIs for consumers that need them
/// (e.g. `meeting_place_matrix`).
///
/// Use [MeetingPlaceMatrixSDK.create] to instantiate.
class MeetingPlaceMatrixSDK implements MeetingPlaceCoreSDK {
  MeetingPlaceMatrixSDK._({
    required MeetingPlaceCoreSDK coreSDK,
    required this.matrixService,
  }) : _coreSDK = coreSDK,
       _senderDidResolver = MatrixSenderDidResolver(
         coreSDK: coreSDK,
         matrixService: matrixService,
       );

  final MeetingPlaceCoreSDK _coreSDK;
  final MatrixSenderDidResolver _senderDidResolver;

  /// The underlying [MatrixService] — exposed for matrix-specific consumers
  /// (e.g. `meeting_place_matrix`) that need VoIP or OpenID token
  /// operations without those APIs leaking through [MeetingPlaceCoreSDK].
  final MatrixService matrixService;

  static Future<MeetingPlaceMatrixSDK> create({
    required Wallet wallet,
    required RepositoryConfig repositoryConfig,
    required MatrixConfig config,
    MeetingPlaceCoreSDKOptions options = const MeetingPlaceCoreSDKOptions(),
    MeetingPlaceCoreSDKLogger? logger,
  }) async {
    MatrixService? matrixServiceRef;

    final coreSDK = await MeetingPlaceCoreSDK.create(
      wallet: wallet,
      repositoryConfig: repositoryConfig,
      config: config,
      options: options,
      logger: logger,
      channelTransportFactory: (controlPlaneSDK) {
        final svc = MatrixService(
          config: config,
          controlPlaneSDK: controlPlaneSDK,
          // TODO(SR): Inject correct logger instance.
          logger: DefaultMeetingPlaceMatrixSDKLogger(
            className: 'MatrixService',
          ),
        );
        matrixServiceRef = svc;
        return MatrixTransport(matrixService: svc);
      },
    );

    return MeetingPlaceMatrixSDK._(
      coreSDK: coreSDK,
      matrixService: matrixServiceRef!,
    );
  }

  /// Broadcast stream of incoming call signals.
  ///
  /// Emits an [IncomingCallSignal] whenever a `ChannelActivity` event with
  /// `type == 'call-invite-video'` or `type == 'call-invite-audio'` is
  /// processed from the control plane. The plugin layer subscribes here to
  /// lazily activate the recipient's Matrix session via [activateIncomingCall]
  /// and emit an `IncomingCallEvent` to the app.
  Stream<IncomingCallSignal> get incomingCallSignals => _coreSDK
      .controlPlaneEventsStream
      .where(
        (e) =>
            e.activityType == CallChannelActivityType.callInviteAudio ||
            e.activityType == CallChannelActivityType.callInviteVideo,
      )
      .asyncMap((e) async {
        return IncomingCallSignal(
          ownChannelDid: e.channel.permanentChannelDid!,
          mediaType: e.activityType == CallChannelActivityType.callInviteVideo
              ? CallMediaType.video
              : CallMediaType.audio,
        );
      });

  /// Broadcast stream of call-decline signals.
  ///
  /// Emits a [CallDeclineSignal] whenever a `ChannelActivity` event with
  /// `type == 'call-decline'` is received. The plugin layer subscribes here
  /// to emit `AudioVideoCallStatus.declined` on the active outgoing session.
  Stream<CallDeclineSignal> get callDeclineSignals => _coreSDK
      .controlPlaneEventsStream
      .where((e) => e.activityType == CallChannelActivityType.callDecline)
      .asyncMap((e) async {
        return CallDeclineSignal(
          // TODO(SR): Rename to permanentChannelDID to be consistent +
          //  error path?
          ownChannelDid: e.channel.permanentChannelDid!,
        );
      });

  // ---------------------------------------------------------------------------
  // MeetingPlaceCoreSDK — delegated members
  // ---------------------------------------------------------------------------

  @override
  Wallet get wallet => _coreSDK.wallet;

  @override
  VdipClient get vdip => _coreSDK.vdip;

  @override
  MeetingPlaceCoreSDKOptions get options => _coreSDK.options;

  @override
  Stream<ChannelAttachmentEvent> get channelAttachments =>
      _coreSDK.channelAttachments;

  @override
  Stream<ControlPlaneStreamEvent> get controlPlaneEventsStream =>
      _coreSDK.controlPlaneEventsStream;

  @override
  MeetingPlaceTransport get channelTransport => _coreSDK.channelTransport;

  @override
  ControlPlaneSDK get discovery => _coreSDK.discovery;

  @override
  MeetingPlaceMediatorSDK get mediator => _coreSDK.mediator;

  @override
  set mediatorDid(String mediatorDid) => _coreSDK.mediatorDid = mediatorDid;

  @override
  set device(Device device) => _coreSDK.device = device;

  @override
  Future<DidManager> generateDid() => _coreSDK.generateDid();

  @override
  Future<DidManager> getDidManager(String did) => _coreSDK.getDidManager(did);

  @override
  Future<OobOfferSession> createOobFlow({
    required ContactCard contactCard,
    String? type,
    String? did,
    String? mediatorDid,
    String? externalRef,
  }) => _coreSDK.createOobFlow(
    contactCard: contactCard,
    type: type,
    did: did,
    mediatorDid: mediatorDid,
    externalRef: externalRef,
  );

  @override
  Future<OobAcceptanceSession> acceptOobFlow(
    Uri oobUrl, {
    required ContactCard contactCard,
    String? type,
    String? externalRef,
    String? did,
    List<Attachment>? attachments,
  }) => _coreSDK.acceptOobFlow(
    oobUrl,
    contactCard: contactCard,
    type: type,
    externalRef: externalRef,
    did: did,
    attachments: attachments,
  );

  @override
  Future<ValidateOfferPhraseResult> validateOfferPhrase(String phrase) =>
      _coreSDK.validateOfferPhrase(phrase);

  @override
  Future<Device> registerForPushNotifications(String deviceToken) =>
      _coreSDK.registerForPushNotifications(deviceToken);

  @override
  Future<RegisterForDidcommNotificationsResult>
  registerForDIDCommNotifications({
    String? mediatorDid,
    String? recipientDid,
  }) => _coreSDK.registerForDIDCommNotifications(
    mediatorDid: mediatorDid,
    recipientDid: recipientDid,
  );

  @override
  Future<PublishOfferResult<T>> publishOffer<T extends ConnectionOffer>({
    required String offerName,
    required SDKConnectionOfferType type,
    required ContactCard contactCard,
    required String offerDescription,
    String? customPhrase,
    DateTime? validUntil,
    int? maximumUsage,
    String? mediatorDid,
    String? metadata,
    String? externalRef,
    ChannelTransport transport = ChannelTransport.didcomm,
    int? score,
  }) => _coreSDK.publishOffer(
    offerName: offerName,
    type: type,
    contactCard: contactCard,
    offerDescription: offerDescription,
    customPhrase: customPhrase,
    validUntil: validUntil,
    maximumUsage: maximumUsage,
    mediatorDid: mediatorDid,
    metadata: metadata,
    externalRef: externalRef,
    transport: transport,
    score: score,
  );

  @override
  Future<FindOfferResult> findOffer({required String mnemonic}) =>
      _coreSDK.findOffer(mnemonic: mnemonic);

  @override
  Future<AcceptOfferResult<T>> acceptOffer<T extends ConnectionOffer>({
    required T connectionOffer,
    required ContactCard contactCard,
    required String senderInfo,
    String? externalRef,
  }) => _coreSDK.acceptOffer(
    connectionOffer: connectionOffer,
    contactCard: contactCard,
    senderInfo: senderInfo,
    externalRef: externalRef,
  );

  @override
  Future<Channel> approveConnectionRequest({
    required Channel channel,
    List<Attachment>? attachments,
  }) => _coreSDK.approveConnectionRequest(
    channel: channel,
    attachments: attachments,
  );

  @override
  Future<Group> rejectConnectionRequest({required Channel channel}) =>
      _coreSDK.rejectConnectionRequest(channel: channel);

  @override
  Future<void> leaveChannel(Channel channel) => _coreSDK.leaveChannel(channel);

  @override
  Future<void> removeMemberFromGroup({
    required String groupId,
    required String memberDid,
  }) => _coreSDK.removeMemberFromGroup(groupId: groupId, memberDid: memberDid);

  @override
  Future<void> sendOutreachInvitation({
    required ConnectionOffer outreachConnectionOffer,
    required ConnectionOffer inviteToConnectionOffer,
    required String messageToInclude,
    required String senderInfo,
  }) => _coreSDK.sendOutreachInvitation(
    outreachConnectionOffer: outreachConnectionOffer,
    inviteToConnectionOffer: inviteToConnectionOffer,
    messageToInclude: messageToInclude,
    senderInfo: senderInfo,
  );

  @override
  Future<void> processControlPlaneEvents({
    void Function(List<Object> errors)? onDone,
  }) => _coreSDK.processControlPlaneEvents(onDone: onDone);

  @override
  void disposeControlPlaneEventsStream() =>
      _coreSDK.disposeControlPlaneEventsStream();

  @override
  Future<void> dispose() => _coreSDK.dispose();

  @override
  Future<void> closeChannelAttachmentsStream() =>
      _coreSDK.closeChannelAttachmentsStream();

  @override
  Future<void> closeVdipStream() => _coreSDK.closeVdipStream();

  @override
  Future<List<String>> deleteControlPlaneEvents() =>
      _coreSDK.deleteControlPlaneEvents();

  @override
  Future<ConnectionOffer?> getConnectionOffer(String offerLink) =>
      _coreSDK.getConnectionOffer(offerLink);

  @override
  Future<ConnectionOffer> markConnectionOfferAsDeleted(
    ConnectionOffer connectionOffer,
  ) => _coreSDK.markConnectionOfferAsDeleted(connectionOffer);

  @override
  Future<void> deleteConnectionOffer(ConnectionOffer connectionOffer) =>
      _coreSDK.deleteConnectionOffer(connectionOffer);

  @override
  Future<Group?> getGroupByOfferLink(String offerLink) =>
      _coreSDK.getGroupByOfferLink(offerLink);

  @override
  Future<Group?> getGroupById(String groupId) => _coreSDK.getGroupById(groupId);

  @override
  Future<void> updateGroup(Group group) => _coreSDK.updateGroup(group);

  @override
  Future<List<ConnectionOffer>> listConnectionOffers() =>
      _coreSDK.listConnectionOffers();

  @override
  Future<List<ConnectionOffer>> getConnectionOffersByExternalRef(
    String externalRef,
  ) => _coreSDK.getConnectionOffersByExternalRef(externalRef);

  @override
  Future<UpdateScoreForOffersResult> updateScoreForOffers({
    required int score,
    required List<ConnectionOffer> offers,
  }) => _coreSDK.updateScoreForOffers(score: score, offers: offers);

  @override
  Future<void> updateLocalConnectionOffersScore({
    required int score,
    required List<ConnectionOffer> offers,
  }) => _coreSDK.updateLocalConnectionOffersScore(score: score, offers: offers);

  @override
  Future<Channel?> getChannelByDid(String did) => _coreSDK.getChannelByDid(did);

  @override
  Future<Channel?> getChannelByOtherPartyPermanentDid(String did) =>
      _coreSDK.getChannelByOtherPartyPermanentDid(did);

  @override
  Future<void> updateChannel(Channel channel) =>
      _coreSDK.updateChannel(channel);

  @override
  Future<String?> getMediatorDidFromUrl(String mediatorEndpoint) =>
      _coreSDK.getMediatorDidFromUrl(mediatorEndpoint);

  @override
  Future<String?> sendMediaMessage(
    Channel channel,
    Uint8List fileBytes, {
    required String contentType,
    String? filename,
    String? caption,
    Map<String, dynamic>? extraContent,
    ChannelNotification? notification,
  }) => _coreSDK.sendMediaMessage(
    channel,
    fileBytes,
    contentType: contentType,
    filename: filename,
    caption: caption,
    extraContent: extraContent,
    notification: notification,
  );

  @override
  Future<Uint8List> downloadMedia(Channel channel, MediaReference reference) =>
      _coreSDK.downloadMedia(channel, reference);

  @override
  Future<Channel> findChannelByDid(String did) =>
      _coreSDK.findChannelByDid(did);

  @override
  Future<Channel?> findChannelByDidOrNull(String did) =>
      _coreSDK.findChannelByDidOrNull(did);

  @override
  Future<void> updateMatrixSyncMarker(Channel channel, String eventId) =>
      _coreSDK.updateMatrixSyncMarker(channel, eventId);

  @override
  Future<void> notifyChannel(ChannelNotification notification) =>
      _coreSDK.notifyChannel(notification);

  // ---------------------------------------------------------------------------
  // Matrix transport overrides
  // ---------------------------------------------------------------------------

  @override
  Future<IncomingMessageHandle> subscribe(
    IncomingMessageSubscription subscription,
  ) async {
    switch (subscription) {
      case MatrixRoomSubscription s:
        final channel = await _coreSDK.findChannelByDid(s.receiverDid);
        final didManager = await _coreSDK.getDidManager(s.receiverDid);
        final participantDids = await _senderDidResolver.fetchParticipantDids(
          channel,
        );
        final stream = _coreSDK.channelTransport.subscribe(
          channel: channel,
          didManager: didManager,
          options: s.options,
          participantDids: participantDids,
        );
        final mapped = stream
            .asyncMap((e) async {
              if (_isTimelineEvent(e)) {
                await _advanceMatrixSyncMarker(s.receiverDid, e.id);
              }
              return _toMatrixIncoming(e, s.receiverDid);
            })
            .where((e) => e != null)
            .cast<MatrixIncomingMessage>();
        return _MatrixIncomingMessageHandle(mapped);
      case DidCommSubscription _:
        return _coreSDK.subscribe(subscription);
      default:
        return _coreSDK.subscribe(subscription);
    }
  }

  @override
  Future<String?> sendMessage(OutgoingMessage message) async {
    switch (message) {
      case MatrixOutgoingMessage m:
        final channel = await _coreSDK.findChannelByDid(m.senderDid);
        final didManager = await _coreSDK.getDidManager(m.senderDid);
        final eventId = await _coreSDK.channelTransport.sendEvent(
          channel: channel,
          type: m.type,
          content: m.content,
          didManager: didManager,
        );
        final notification = m.notification;
        if (notification != null) {
          unawaited(
            _coreSDK
                .notifyChannel(notification)
                .catchError((Object _, StackTrace _) {}),
          );
        }
        return eventId;
      default:
        return _coreSDK.sendMessage(message);
    }
  }

  @override
  Future<List<IncomingMessage>> fetchHistory(HistoryQuery query) async {
    switch (query) {
      case MatrixRoomHistoryQuery q:
        final channel = await _coreSDK.findChannelByDid(q.receiverDid);
        final didManager = await _coreSDK.getDidManager(q.receiverDid);
        final events = await _coreSDK.channelTransport.fetchHistory(
          channel: channel,
          didManager: didManager,
          limit: q.limit,
          since: q.since,
        );

        if (q.updateChannelSyncMarker && events.isNotEmpty) {
          await _coreSDK.updateMatrixSyncMarker(channel, events.last.id);
        }

        return Future.wait(
          events.map((e) => _toMatrixIncoming(e, q.receiverDid)),
        ).then((mapped) => mapped.whereType<MatrixIncomingMessage>().toList());
      case DidCommHistoryQuery _:
        return _coreSDK.fetchHistory(query);
      default:
        return _coreSDK.fetchHistory(query);
    }
  }

  /// Requests a Matrix OpenID token for [didManager].
  ///
  /// The returned `OpenIdCredentials` can be passed directly to
  /// `LiveKitTokenService.fetchToken` to obtain a LiveKit JWT via
  /// `lk-jwt-service` — no server-side secrets are required on the client.
  ///
  /// Throws if the Matrix session has not been established.
  /// Ensure a Matrix login has been performed first.
  ///
  /// TODO(SR): Is this needed on consumer side?
  Future<matrix.OpenIdCredentials> getMatrixOpenIdToken(
    DidManager didManager,
  ) => matrixService.getOpenIdToken(didManager);

  /// Returns the Matrix device ID for the active session of [didManager].
  ///
  /// Pass this to `SfuTokenService.fetchToken` as `deviceId` so lk-jwt-service
  /// can set the LiveKit participant identity to `userId:deviceId`, matching
  /// the MatrixRTC participant ID format used for E2EE key distribution.
  ///
  /// TODO(SR): Is this needed on consumer side?
  Future<String?> getMatrixDeviceId(DidManager didManager) =>
      matrixService.getDeviceId(didManager);

  /// Returns the deterministic LiveKit room name for a channel.
  ///
  /// Both parties in the channel derive the same name without coordination —
  /// pass the local user's [channelDid] and the other party's
  /// [otherPartyChannelDid] in either order; the result is commutative.
  ///
  /// Pass the returned value as the `roomName` argument to
  /// `LiveKitTokenService.fetchToken`.
  String livekitRoomName({
    required String channelDid,
    String? otherPartyChannelDid,
  }) => deriveRoomAliasLocalpart(
    channelDid: channelDid,
    otherPartyChannelDid: otherPartyChannelDid,
  );

  /// Resolves the Matrix room ID for [channel].
  ///
  /// Uses the deterministic room alias derived from the channel DIDs. Requires
  /// a Matrix session for [didManager] to have been established first.
  ///
  /// TODO(SR): Is this needed on consumer side?
  Future<String> resolveMatrixRoomIdForChannel({
    required DidManager didManager,
    required Channel channel,
  }) => matrixService.resolveRoomIdForChannel(
    didManager: didManager,
    channel: channel,
  );

  /// Injects the [matrix.VoIP] instance required for MatrixRTC call management.
  ///
  /// Call this once at app startup, passing a [matrix.VoIP] created with a
  /// concrete [matrix.WebRTCDelegate]. Must be called before [startVideoCall],
  /// [leaveVideoCall], or [watchVideoCall].
  ///
  /// TODO(SR): Is this needed on consumer side?
  void initializeMatrixRTC(matrix.VoIP voip) {
    matrixService.initializeVoIP(voip);
  }

  /// Initializes MatrixRTC from a [matrix.WebRTCDelegate] by creating the
  /// [matrix.VoIP] instance internally.
  ///
  /// Call this at app startup before the first [startVideoCall]. Uses the
  /// authenticated Matrix session for [didManager] to create the VoIP object,
  /// so the Matrix session must be established first (call
  /// `loginWithDid` if needed).
  ///
  /// TODO(SR): Is this needed on consumer side?
  Future<void> initializeMatrixRTCWithDelegate({
    required DidManager didManager,
    required matrix.WebRTCDelegate delegate,
  }) => matrixService.initializeVoIPWithDelegate(
    didManager: didManager,
    delegate: delegate,
  );

  /// Lazily activates the Matrix session for [didManager] and resolves the
  /// pending incoming MatrixRTC group call published in [roomId].
  ///
  /// Call this after an out-of-band signal (call push or mediator message)
  /// reports an incoming call for a specific channel. It brings up only that
  /// one DID's session, initialises VoIP with [delegate] when needed, and
  /// returns the [matrix.GroupCallSession] the caller can join.
  ///
  /// Throws when no group call surfaces in [roomId] within the activation
  /// timeout.
  ///
  /// TODO(SR): Is this needed on consumer side?
  Future<matrix.GroupCallSession> activateIncomingCall({
    required DidManager didManager,
    required matrix.WebRTCDelegate delegate,
    required String roomId,
  }) => matrixService.activateIncomingCall(
    didManager: didManager,
    delegate: delegate,
    roomId: roomId,
  );

  /// Returns the Matrix participant identity string for the local device.
  ///
  /// The format is `userId:deviceId`. Used as the LiveKit participant identity
  /// to map per-participant E2EE keys between Matrix and LiveKit.
  ///
  /// Returns `null` if no authenticated session exists for [didManager].
  ///
  /// TODO(SR): Is this needed on consumer side?
  Future<String?> matrixParticipantId(DidManager didManager) =>
      matrixService.ownMatrixIdentity(didManager);

  /// Creates or joins a MatrixRTC group call in [roomId].
  ///
  /// Publishes an `m.call.member` state event so the remote party can discover
  /// the LiveKit room. The [livekitServiceUrl] and [livekitAlias] identify the
  /// LiveKit server and room. An optional [callId] may be supplied for
  /// idempotent session creation; defaults to [roomId].
  ///
  /// TODO(SR): Is this needed on consumer side?
  Future<matrix.GroupCallSession> startVideoCall({
    required DidManager didManager,
    required String roomId,
    required String livekitServiceUrl,
    required String livekitAlias,
    String? callId,
  }) => matrixService.startCall(
    didManager: didManager,
    roomId: roomId,
    livekitServiceUrl: livekitServiceUrl,
    livekitAlias: livekitAlias,
    callId: callId,
  );

  /// Returns `true` when [roomId] already has an active (non-expired)
  /// MatrixRTC call membership.
  ///
  /// Call before initiating an outbound call to decide whether to broadcast a
  /// fresh call-invite or simply rejoin a call that is already in progress
  /// (for example after an app restart re-enters the call screen).
  ///
  /// TODO(SR): Is this needed on consumer side?
  Future<bool> hasActiveVideoCall({
    required DidManager didManager,
    required String roomId,
  }) => matrixService.hasActiveCallMembership(
    didManager: didManager,
    roomId: roomId,
  );

  /// Returns the callId of the active (non-expired) MatrixRTC call in [roomId],
  /// or `null` when no call is in progress.
  ///
  /// A device joining or rejoining an in-progress call must reuse this exact
  /// callId. A fresh caller generates a new callId instead, so stale E2EE keys
  /// from a previous, ended call generation are dropped rather than
  /// overwriting the current key at index 0.
  ///
  /// TODO(SR): Is this needed on consumer side?
  Future<String?> activeVideoCallId({
    required DidManager didManager,
    required String roomId,
  }) => matrixService.activeCallId(didManager: didManager, roomId: roomId);

  /// Leaves the active MatrixRTC group call in [roomId] with [callId].
  ///
  /// TODO(SR): Is this needed on consumer side?
  Future<void> leaveVideoCall({
    required String roomId,
    required String callId,
  }) => matrixService.leaveCall(roomId: roomId, callId: callId);

  /// Returns a stream of MatrixRTC call events for the given [roomId] and
  /// [callId].
  ///
  /// Returns `null` if VoIP has not been initialized or no session exists for
  /// the given IDs.
  ///
  /// TODO(SR): Is this needed on consumer side?
  Stream<matrix.MatrixRTCCallEvent>? watchVideoCall({
    required String roomId,
    required String callId,
  }) => matrixService.watchCall(roomId: roomId, callId: callId);

  @visibleForTesting
  @override
  Future<void> waitForRoomEncryptionReady({
    required String localDid,
    required Iterable<String> expectedDids,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final channel = await _coreSDK.findChannelByDid(localDid);
    final didManager = await _coreSDK.getDidManager(localDid);
    final roomId = await matrixService.resolveRoomIdForChannel(
      didManager: didManager,
      channel: channel,
    );
    await matrixService.waitForRoomEncryptionReady(
      roomId: roomId,
      didManager: didManager,
      expectedDids: expectedDids,
      timeout: timeout,
    );
  }

  bool _isTimelineEvent(TransportEvent event) {
    return event.type != 'm.typing' && event.type != 'm.receipt';
  }

  Future<MatrixIncomingMessage?> _toMatrixIncoming(
    TransportEvent e,
    String receiverDid,
  ) async {
    final resolved =
        e.senderDid ??
        await _senderDidResolver.resolve(
          receiverDid: receiverDid,
          matrixUserId: e.metadata?['sender_id'] as String,
        );
    if (resolved == null) return null;

    return MatrixIncomingMessage(
      senderDid: resolved,
      timestamp: e.timestamp,
      roomId: e.channelId,
      eventId: e.id,
      type: e.type,
      content: e.content,
      isFromMe: e.isFromMe,
      stateKey: e.metadata?['state_key'] as String?,
    );
  }

  Future<void> _advanceMatrixSyncMarker(
    String receiverDid,
    String eventId,
  ) async {
    final channel = await _coreSDK.findChannelByDidOrNull(receiverDid);
    if (channel == null) return;
    await _coreSDK.updateMatrixSyncMarker(channel, eventId);
  }
}

class _MatrixIncomingMessageHandle implements IncomingMessageHandle {
  _MatrixIncomingMessageHandle(this.stream);

  @override
  final Stream<IncomingMessage> stream;

  @override
  Future<void> dispose() async {}
}
